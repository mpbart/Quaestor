# frozen_string_literal: true

require 'cache_manager'
require 'finance_manager/interface'
require 'finance_manager/plaid_client'

class PlaidController < ActionController::Base
  before_action :authenticate_user!
  skip_before_action :verify_authenticity_token
  TOKEN_REGEX = /\w+-\w+-\w{8}-\w{4}-\w{4}-\w{4}-\w{12}/

  # rubocop:disable Naming/AccessorMethodName
  # Add accounts from new financial institution for user
  # TODO: Move logic to plaid client?
  def get_access_token
    params.permit(:public_token)
    public_token = params[:public_token]
    return unless valid_public_token?(public_token)

    request = Plaid::ItemPublicTokenExchangeRequest.new
    request.public_token = public_token

    response = finance_manager.plaid_client.item_public_token_exchange(request)
    credential = PlaidCredential.create!(plaid_item_id: response.item_id,
                                         access_token:  response.access_token,
                                         user:          current_user)
    finance_manager.add_institution_information(credential)

    render json: { success: true }
  end
  # rubocop:enable Naming/AccessorMethodName

  def refresh_accounts
    failed_accounts = finance_manager.refresh_accounts
    failed_accounts += finance_manager.refresh_transactions
    DatabaseBackupWorker.perform_async

    render json: { status: 'complete', failed_accounts: failed_accounts.uniq }
  end

  def create_link_token
    link_token = CacheManager.get(:plaid_link_token, current_user.id)

    render json: { link_token: link_token }
  end

  # TODO: Move this logic to cache manager and plaid client
  def fix_account_connection
    access_token = PlaidCredential.find_by(
      institution_name: Account.find(params[:account_id]).institution_name
    ).access_token

    link_token_create_request = Plaid::LinkTokenCreateRequest.new(
      {
        user:          { client_user_id: current_user.id.to_s },
        client_name:   'personal-dash',
        access_token:  access_token,
        country_codes: ['US'],
        language:      'en'
      }
    )

    link_token_response = plaid_client.client.link_token_create(
      link_token_create_request
    )

    render json: { link_token: link_token_response.link_token }
  end

  private

  def finance_manager
    @finance_manager ||= FinanceManager::Interface.new(current_user)
  end

  # TODO: Eventually refactor this out but leave for now to keep the number of
  # changes under control
  def plaid_client
    @plaid_client ||= FinanceManager::PlaidClient.new
  end

  def valid_public_token?(token)
    TOKEN_REGEX =~ token
  end
end
