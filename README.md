# README
## Overview
This is a locally-hostable Personal Finance Manager built with a focus on simplicity and ease of use. It can be used to categorize transactions, create a budget, track changes in spending and income over time, and analyze your net worth.

Quickstart:
1. Build the docker image with `docker compose build`
2. Setup the database with `docker compose run web bin/prep_db`
3. Fill out config.json with private keys necessary to authenticate with 3rd party APIs. Currently only Plaid is required which needs:
  * client_id
  * secret
  * environment (map your app's environment to plaid's environment)
4. Start the application with `docker compose up` and navigate to http://localhost:2424
