FROM ruby:3.2.2-bookworm

CMD ["run_app"]

ENTRYPOINT ["bin/entrypoint.sh"]

RUN sh -c 'wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -'
RUN sh -c 'echo "deb https://apt.postgresql.org/pub/repos/apt bookworm-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
RUN apt-get update && apt-get install -y postgresql-17 postgresql-client-17

RUN mkdir /code
WORKDIR /code

COPY Gemfile Gemfile.lock ./

RUN bundle install --jobs 20 --retry 3

COPY . ./

# tmp/ and log/ are gitignored (nothing tracked under them), so a fresh
# checkout - which is what the GHA build uses - has neither. Create them so
# puma can write tmp/pids/server.pid, Rails can write log/*.log, and sprockets
# can use tmp/cache. Without this the container fails to boot.
RUN mkdir -p tmp/pids tmp/cache log
