# frozen_string_literal: true

require 'plaid'

module FinanceManager
  class PlaidClient
    ITEM_LOGIN_REQUIRED = 'ITEM_LOGIN_REQUIRED'

    AccountsResponse = Struct.new(:accounts, :failed_institution_name)
    TransactionsResponse = Struct.new(:added, :modified, :removed, :cursor,
                                      :failed_institution_name)

    attr_reader :api_client

    def initialize
      plaid_config = Plaid::Configuration.new
      plaid_config.server_index = Plaid::Configuration::Environment['production']
      plaid_config.api_key['PLAID-CLIENT-ID'] = ENV.fetch('PLAID_CLIENT_ID')
      plaid_config.api_key['PLAID-SECRET'] = ENV.fetch('PLAID_SECRET_ID')

      api_client = Plaid::ApiClient.new(plaid_config)

      @api_client = Plaid::PlaidApi.new(api_client)
    end

    def sync_accounts(plaid_credential)
      return_value = AccountsResponse.new
      request = Plaid::AccountsGetRequest.new({ access_token: plaid_credential.access_token })
      plaid_response = api_client.accounts_get(request)
      PlaidResponse.record_accounts_response!(plaid_response.to_hash, plaid_credential)

      return_value.accounts = plaid_response.accounts
    rescue Plaid::ApiError => e
      body = JSON.parse(e.response_body)
      raise e unless body['error_code'] == ITEM_LOGIN_REQUIRED

      return_value.failed_institution_name = plaid_credential.institution_name
      Rails.logger.error("Failed to sync accounts #{plaid_credential.institution_name} - #{e}")
    ensure
      return return_value
    end

    def sync_transactions(plaid_credential)
      transactions_remaining = true
      cursor = transactions_cursor(plaid_credential)
      added = []
      modified = []
      removed = []
      return_value = TransactionsResponse.new

      while transactions_remaining
        request = Plaid::TransactionsSyncRequest.new(
          access_token: plaid_credential.access_token,
          cursor:       cursor
        )
        plaid_response = api_client.transactions_sync(request)
        PlaidResponse.record_transactions_response!(plaid_response.to_hash, plaid_credential)

        added.concat(plaid_response.added)
        modified.concat(plaid_response.modified)
        removed.concat(plaid_response.removed)

        transactions_remaining = plaid_response.has_more
        cursor = plaid_response.next_cursor
      end

      return_value.added = added
      return_value.removed = removed
      return_value.modified = modified
      return_value.cursor = cursor
    rescue Plaid::ApiError => e
      body = JSON.parse(e.response_body)
      raise e unless body['error_code'] == ITEM_LOGIN_REQUIRED

      return_value.failed_institution_name = plaid_credential.institution_name
      Rails.logger.error(
        "Failed to sync transactions for #{plaid_credential.institution_name} - #{e}"
      )
    ensure
      return return_value
    end

    def get_institution_information!(plaid_credential)
      item_request = Plaid::ItemGetRequest.new({ access_token: plaid_credential.access_token })
      response = plaid_client.item_get(item_request)

      request = Plaid::InstitutionsGetByIdRequest.new(
        {
          institution_id: response.item.institution_id,
          country_codes:  ['US']
        }
      )
      response = plaid_client.institutions_get_by_id(request)

      plaid_credential.update_columns(
        institution_id:   response.institution.institution_id,
        institution_name: response.institution.name
      )
    end

    def create_link_token(user_id)
      link_token_create_request = Plaid::LinkTokenCreateRequest.new(
        {
          user:          { client_user_id: user_id.to_s },
          client_name:   'personal-dash',
          # Might need to only have transactions since it expects the linked institution to
          # have accounts with all types listed below
          products:      %w[
            transactions
          ],
          country_codes: ['US'],
          language:      'en'
        }
      )
      api_client.link_token_create(link_token_create_request)
    end

    private

    def transactions_cursor(plaid_credential)
      plaid_credential.cursor || 'now'
    end
  end
end
