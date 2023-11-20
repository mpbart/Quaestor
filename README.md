# README
## Overview
This is a Personal Finance Manager I'm building for personal use. The main use case is tracking finances, creating a budget, tracking changes in spending and income over time, etc.

Quickstart:
1. Build the docker image with `docker compose build`
2. Setup the database with `docker compose run web bin/prep_db`
3. Start the application with `docker compose up` and navigate to http://localhost:2424
4. Fill out config.json with private keys necessary to authenticate with 3rd party clients. Currently that's only plaid which requires:
  * client_id
  * secret
  * environment (map your app's environment to plaid's environment)
