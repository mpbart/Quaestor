# README
## Overview
[![Test Suite](https://github.com/mpbart/Quaestor/actions/workflows/rspec.yml/badge.svg)](https://github.com/mpbart/Quaestor/actions/workflows/rspec.yml)

Quaestor is a locally-hostable Personal Finance Manager built with a focus on simplicity and ease of use. It can be used to categorize transactions, create a budget, track changes in spending and income over time, and analyze changes to your net worth.

Quickstart:
1. Build the docker image with `docker compose build`
2. Setup the database with `docker compose run web bin/prep_db`
3. Add the values necessary for plaid authentication to the `docker-compose.yml` file:
  * `PLAID_CLIENT_ID`
  * `PLAID_SECRET_ID`
4. Start the application with `docker compose up` and navigate to http://localhost:2424
