# README
## Overview
This is a CRM I'm building for personal use. My main use case is a personal finance manager that I can use to track my finances, create a budget, track changes in spending overtime, etc.

* Supports ruby version 2.6.5
* Fill out config.json with private keys necessary to authenticate with 3rd party clients. Currently that's only plaid which requires:
  - client_id
  - secret
  - public_key
  - environment (map your app's environment to plaid's environment)
