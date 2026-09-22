#!/usr/bin/env bash
#
# Production smoke test.
#
# Boots the compose stack (web, sidekiq, postgres, redis) in production mode
# using throwaway credentials (docker-compose.ci.yml), then exercises the
# running server over HTTP and checks that background jobs flow through Redis
# and Sidekiq.
#
# Used by .github/workflows/rspec.yml, and runnable locally:
#
#   docker compose build        # once, so the image exists
#   bin/ci_smoke_test.sh
#
# Requires: docker with the compose plugin, curl.
#
# Deliberately out of scope, because neither is reachable over HTTP from a
# booted server and both need in-process stubbing - they are covered by the
# RSpec suite instead:
#   * Plaid account/transaction refresh (spec/integration/lib/finance_manager)
#   * CSV attachment and import (spec/integration/models/user_transaction_csvs_spec.rb,
#     which also documents that the controller action is currently unrouted)
set -euo pipefail

cd "$(dirname "$0")/.."

PORT="${SMOKE_PORT:-2424}"
BASE_URL="http://localhost:${PORT}"
COMPOSE=(docker compose --env-file .env.test -f docker-compose.yml -f docker-compose.ci.yml)

WORK_DIR="$(mktemp -d)"
COOKIE_JAR="${WORK_DIR}/cookies.txt"
PAGE="${WORK_DIR}/page.html"
BODY="${WORK_DIR}/body.txt"
ASSET_LIST="${WORK_DIR}/assets.txt"
ASSET_BODY="${WORK_DIR}/asset-body.txt"
HEADERS="${WORK_DIR}/headers.txt"

# Set once the app container is serving, so diagnostics can query it.
DIAG_READY=false

step() { printf '\n== %s\n' "$1"; }
pass() { printf '   ok: %s\n' "$1"; }

dump_logs() {
  printf '\n--- container logs ---\n' >&2
  "${COMPOSE[@]}" logs --tail=80 web sidekiq >&2 2>&1 || true
}

# A failing assertion here is usually caused by state the driver cannot see
# (which database the app is on, whether the seed landed, whether Devise
# rejects the credentials). Print that state so a CI failure is actionable
# without having to reproduce it locally.
diagnose() {
  printf '\n--- diagnostics ---\n' >&2
  if [ -s "$HEADERS" ]; then
    printf '\nlast response headers:\n' >&2
    sed -n '1,30p' "$HEADERS" >&2 2>/dev/null || true
  fi
  if [ -s "$BODY" ]; then
    printf '\nlast response body:\n' >&2
    sed -n '1,40p' "$BODY" >&2 2>/dev/null || true
  fi
  if [ -s "$COOKIE_JAR" ]; then
    printf '\ncookies:\n' >&2
    cat "$COOKIE_JAR" >&2 2>/dev/null || true
  fi
  if [ "$DIAG_READY" = 'true' ]; then
    printf '\napp-side database and credential check:\n' >&2
    "${COMPOSE[@]}" exec -T \
      -e "SMOKE_USER_EMAIL=${SMOKE_USER_EMAIL:-}" \
      -e "SMOKE_USER_PASSWORD=${SMOKE_USER_PASSWORD:-}" \
      web bundle exec rails runner '
        email = ENV.fetch("SMOKE_USER_EMAIL")
        password = ENV.fetch("SMOKE_USER_PASSWORD")
        user = User.find_by(email: email)
        puts "SMOKE_DB=#{ActiveRecord::Base.connection.current_database}"
        puts "SMOKE_USER_COUNT=#{User.count}"
        puts "SMOKE_USER_FOUND=#{!user.nil?}"
        puts "SMOKE_PASSWORD_VALID=#{!user.nil? && user.valid_password?(password)}"
      ' >&2 2>&1 || true
  fi
  dump_logs
}

fail() {
  printf '   FAIL: %s\n' "$1" >&2
  diagnose || true
  exit 1
}

cleanup() { rm -rf "$WORK_DIR"; }
trap cleanup EXIT
trap dump_logs ERR

# ---------------------------------------------------------------------------
# Boot
# ---------------------------------------------------------------------------

step 'Preparing the production database'
"${COMPOSE[@]}" up -d db redis >/dev/null
# crm_ci is a throwaway database in a throwaway container, so the protected
# environment guard is explicitly waived rather than worked around by using the
# test environment.
"${COMPOSE[@]}" run --rm -e DISABLE_DATABASE_ENVIRONMENT_CHECK=1 \
  web bundle exec rails db:create db:schema:load
pass 'crm_ci created and schema loaded'

step 'Booting web and sidekiq in production'
"${COMPOSE[@]}" up -d web sidekiq

ready=false
for _ in $(seq 1 60); do
  if [ "$(curl -s --max-time 5 -o /dev/null -w '%{http_code}' "${BASE_URL}/users/sign_in" || true)" = '200' ]; then
    ready=true
    break
  fi
  sleep 2
done
[ "$ready" = 'true' ] || fail "web server never served /users/sign_in (waited 120s)"
DIAG_READY=true
pass 'puma booted and served the sign-in page'

# The credentials are defined here and pushed into the container, rather than
# read back out of it: only the generated ids need to round-trip, and both are
# asserted below. That keeps the password out of the captured stdout, where
# stray whitespace or interleaved output would silently corrupt it into a
# failed sign-in.
SMOKE_USER_EMAIL="${SMOKE_USER_EMAIL:-smoke@example.com}"
SMOKE_USER_PASSWORD="${SMOKE_USER_PASSWORD:-ci-smoke-password}"

step 'Seeding fixtures'
FIXTURES="$("${COMPOSE[@]}" exec -T \
  -e "SMOKE_USER_EMAIL=${SMOKE_USER_EMAIL}" \
  -e "SMOKE_USER_PASSWORD=${SMOKE_USER_PASSWORD}" \
  web bundle exec rails runner bin/ci_smoke_fixtures.rb | tr -d '\r' | grep '^SMOKE_' || true)"
[ -n "$FIXTURES" ] || fail 'fixture script produced no SMOKE_ output'
SMOKE_TRANSACTION_ID="$(sed -n 's/^SMOKE_TRANSACTION_ID=//p' <<<"$FIXTURES")"
[ -n "$SMOKE_TRANSACTION_ID" ] || fail 'fixture script did not report a transaction id'
pass "fixtures ready for ${SMOKE_USER_EMAIL}"

step 'Verifying the seeded credentials inside the app container'
# Confirms the fixture row landed in the database the app is actually on, and
# that Devise accepts the password, before any HTTP is involved. Without this,
# a mismatch between the seed and the app only surfaces as an opaque 200 from
# the sign-in POST.
CHECK="$("${COMPOSE[@]}" exec -T \
  -e "SMOKE_USER_EMAIL=${SMOKE_USER_EMAIL}" \
  -e "SMOKE_USER_PASSWORD=${SMOKE_USER_PASSWORD}" \
  web bundle exec rails runner '
    email = ENV.fetch("SMOKE_USER_EMAIL")
    password = ENV.fetch("SMOKE_USER_PASSWORD")
    user = User.find_by(email: email)
    valid = !user.nil? && user.valid_password?(password)
    puts "SMOKE_DB=#{ActiveRecord::Base.connection.current_database}"
    puts "SMOKE_USER_COUNT=#{User.count}"
    puts "SMOKE_USER_FOUND=#{!user.nil?}"
    puts "SMOKE_PASSWORD_VALID=#{valid}"
  ' | tr -d '\r' || true)"
printf '%s\n' "$CHECK" | sed 's/^/   /'
grep -q '^SMOKE_PASSWORD_VALID=true$' <<<"$CHECK" ||
  fail 'the app container cannot authenticate the seeded user'
pass "app container authenticates ${SMOKE_USER_EMAIL} against $(sed -n 's/^SMOKE_DB=//p' <<<"$CHECK")"

# ---------------------------------------------------------------------------
# HTTP: authentication
# ---------------------------------------------------------------------------

step 'Authentication'
REDIRECT="$(curl -s --max-time 10 -o /dev/null -w '%{redirect_url}' "${BASE_URL}/")"
case "$REDIRECT" in
  *'/users/sign_in'*) pass "GET / redirects to sign-in (${REDIRECT})" ;;
  *) fail "GET / should redirect to sign-in, got '${REDIRECT}'" ;;
esac

curl -s --max-time 10 -o "$PAGE" -c "$COOKIE_JAR" "${BASE_URL}/users/sign_in"
# A CSRF token is only emitted when forgery protection is enabled, which is how
# we confirm the server really is running the production (not test) config.
TOKEN="$(sed -n 's/.*name="authenticity_token" value="\([^"]*\)".*/\1/p' "$PAGE" | head -n 1)"
[ -n "$TOKEN" ] || fail 'sign-in page has no authenticity token, so CSRF protection looks disabled'

STATUS="$(curl -s --max-time 10 -o "$BODY" -D "$HEADERS" -b "$COOKIE_JAR" -c "$COOKIE_JAR" -w '%{http_code}' \
  -X POST "${BASE_URL}/users/sign_in" \
  -H "Origin: ${BASE_URL}" \
  --data-urlencode "authenticity_token=${TOKEN}" \
  --data-urlencode "user[email]=${SMOKE_USER_EMAIL}" \
  --data-urlencode "user[password]=${SMOKE_USER_PASSWORD}")"
[ "$STATUS" = '302' ] || fail "sign-in returned ${STATUS}, expected a 302 redirect"
pass 'signed in through Devise over HTTP'

STATUS="$(curl -s --max-time 10 -o "$PAGE" -b "$COOKIE_JAR" -c "$COOKIE_JAR" \
  -w '%{http_code}' "${BASE_URL}/transactions")"
[ "$STATUS" = '200' ] || fail "GET /transactions returned ${STATUS} for an authenticated session"
TOKEN="$(sed -n \
  -e 's/.*<meta[^>]*name="csrf-token"[^>]*content="\([^"]*\)"[^>]*>.*/\1/p' \
  -e 's/.*<meta[^>]*content="\([^"]*\)"[^>]*name="csrf-token"[^>]*>.*/\1/p' \
  "$PAGE" | head -n 1)"
[ -n "$TOKEN" ] || fail 'authenticated page has no CSRF token'
pass 'transaction index renders for the signed-in user'

# ---------------------------------------------------------------------------
# HTTP: finance flows
# ---------------------------------------------------------------------------

step 'Transaction editing and splitting'
STATUS="$(curl -s --max-time 10 -o "$BODY" -b "$COOKIE_JAR" -w '%{http_code}' \
  -X PATCH "${BASE_URL}/transactions/${SMOKE_TRANSACTION_ID}" \
  -H "Origin: ${BASE_URL}" \
  --data-urlencode "authenticity_token=${TOKEN}" \
  --data-urlencode 'transaction[description]=CI smoke transaction (edited)')"
[ "$STATUS" = '200' ] || fail "PATCH /transactions/${SMOKE_TRANSACTION_ID} returned ${STATUS}"
grep -q '"success":true' "$BODY" || fail "transaction update did not report success: $(cat "$BODY")"
pass 'transaction update returns {"success":true}'

STATUS="$(curl -s --max-time 10 -o "$BODY" -b "$COOKIE_JAR" -w '%{http_code}' \
  -X POST "${BASE_URL}/split_transactions" \
  -H "Origin: ${BASE_URL}" \
  --data-urlencode "authenticity_token=${TOKEN}" \
  --data-urlencode 'transaction[amount]=10.0' \
  --data-urlencode "transaction[parent_transaction_id]=${SMOKE_TRANSACTION_ID}")"
[ "$STATUS" = '200' ] || fail "POST /split_transactions returned ${STATUS}"
grep -q '"success":true' "$BODY" || fail "transaction split did not report success: $(cat "$BODY")"
pass 'transaction split returns {"success":true}'

step 'Analytics, rules and JSON endpoints'
STATUS="$(curl -s --max-time 10 -o /dev/null -b "$COOKIE_JAR" -w '%{http_code}' "${BASE_URL}/analytics")"
[ "$STATUS" = '200' ] || fail "GET /analytics returned ${STATUS}"
pass 'analytics page renders'

STATUS="$(curl -s --max-time 10 -o /dev/null -b "$COOKIE_JAR" -w '%{http_code}' "${BASE_URL}/rules")"
[ "$STATUS" = '200' ] || fail "GET /rules returned ${STATUS}"
pass 'rules page renders'

CHART_URL="${BASE_URL}/chart_data/spending_over_timeframe?start_date=2020-01-01&end_date=2030-01-01"
STATUS="$(curl -s --max-time 10 -o "$BODY" -b "$COOKIE_JAR" -w '%{http_code}' "$CHART_URL")"
[ "$STATUS" = '200' ] || fail "GET ${CHART_URL} returned ${STATUS}"
case "$(cat "$BODY")" in
  \[*|{*) pass 'chart_data responds with JSON' ;;
  *) fail "chart_data did not return JSON: $(cat "$BODY")" ;;
esac

# ---------------------------------------------------------------------------
# HTTP: Turbo and page assets
# ---------------------------------------------------------------------------

step 'Turbo wiring and production assets'
grep -q 'transactions-table-body' "$PAGE" ||
  fail 'the transactions page has no transactions-table-body, which the Turbo broadcast stream targets'
pass 'the Turbo stream target the transaction broadcasts render into exists'

: > "$ASSET_LIST"
for page_path in /transactions /analytics; do
  curl -s --max-time 10 -o "$PAGE" -b "$COOKIE_JAR" "${BASE_URL}${page_path}"
  grep -oE "/assets/[^\"'<>  ]+" "$PAGE" >> "$ASSET_LIST" || true
done
sort -u -o "$ASSET_LIST" "$ASSET_LIST"
[ -s "$ASSET_LIST" ] || fail 'no /assets/ URLs were found on the rendered pages'

asset_count=0
while read -r asset; do
  [ -n "$asset" ] || continue
  STATUS="$(curl -s --max-time 10 -o "$ASSET_BODY" -w '%{http_code}' "${BASE_URL}${asset}")"
  [ "$STATUS" = '200' ] || fail "${asset} returned ${STATUS} in production mode"
  case "$asset" in
    *.css)
      grep -qi 'text/css' <(curl -s --max-time 10 -o /dev/null -w '%{content_type}' "${BASE_URL}${asset}") ||
        fail "${asset} was not served as text/css"
      ;;
  esac
  asset_count=$((asset_count + 1))
done < "$ASSET_LIST"
pass "${asset_count} page-specific and shared assets resolve in production mode"

# ---------------------------------------------------------------------------
# Action Cable
# ---------------------------------------------------------------------------

step 'Action Cable'
CABLE_STATUS="$(curl -s --max-time 10 -o /dev/null -w '%{http_code}' \
  -H 'Connection: Upgrade' \
  -H 'Upgrade: websocket' \
  -H 'Sec-WebSocket-Version: 13' \
  -H 'Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==' \
  "${BASE_URL}/cable")"
case "$CABLE_STATUS" in
  101|400|404)
    pass "/cable answered a websocket handshake with ${CABLE_STATUS}"
    ;;
  *)
    fail "/cable returned an unexpected status ${CABLE_STATUS}"
    ;;
esac

# ---------------------------------------------------------------------------
# Sidekiq and Redis
# ---------------------------------------------------------------------------

step 'Sidekiq consuming jobs'
"${COMPOSE[@]}" exec -T redis redis-cli -n 0 ping >/dev/null
pass 'redis is reachable'

"${COMPOSE[@]}" exec -T web bundle exec rails runner \
  'require "sidekiq/api"; BalancesWorker.perform_async; puts "SMOKE_QUEUED=#{Sidekiq::Queue.new.size}"' >/dev/null

drained=false
for _ in $(seq 1 30); do
  if [ "$("${COMPOSE[@]}" exec -T redis redis-cli -n 0 llen queue:default | tr -d '\r')" = '0' ]; then
    drained=true
    break
  fi
  sleep 2
done
[ "$drained" = 'true' ] || fail 'sidekiq did not consume the enqueued job within 60s'

RETRIES="$("${COMPOSE[@]}" exec -T redis redis-cli -n 0 zcard retry | tr -d '\r')"
[ "$RETRIES" = '0' ] || fail "sidekiq recorded ${RETRIES} failed job(s) while draining"
pass 'sidekiq consumed the job without errors'

# ---------------------------------------------------------------------------
# Background backup job enqueueing
# ---------------------------------------------------------------------------

step 'Database backup job enqueueing'
# Stop the worker first so the enqueued backup is not executed during the test.
"${COMPOSE[@]}" stop sidekiq >/dev/null
"${COMPOSE[@]}" exec -T redis redis-cli -n 0 del queue:default >/dev/null

STATUS="$(curl -s --max-time 10 -o "$BODY" -b "$COOKIE_JAR" -w '%{http_code}' \
  -X POST "${BASE_URL}/accounts/backup" \
  -H "Origin: ${BASE_URL}" \
  --data-urlencode "authenticity_token=${TOKEN}")"
[ "$STATUS" = '200' ] || fail "POST /accounts/backup returned ${STATUS}"
grep -q '"success":true' "$BODY" || fail "backup request did not report success: $(cat "$BODY")"

DEPTH="$("${COMPOSE[@]}" exec -T redis redis-cli -n 0 llen queue:default | tr -d '\r')"
[ "$DEPTH" = '1' ] || fail "expected exactly one queued backup job, found ${DEPTH}"
"${COMPOSE[@]}" exec -T redis redis-cli -n 0 del queue:default >/dev/null
pass 'backup request enqueued DatabaseBackupWorker'

printf '\nProduction smoke test passed.\n'
