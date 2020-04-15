require 'plaid'
require 'config_reader'

class PlaidController < ActionController::Base
  before_action :authenticate_user!
  skip_before_action :verify_authenticity_token
  TOKEN_REGEX = /\w+-\w+-\w{8}-\w{4}-\w{4}-\w{4}-\w{12}/

  def get_access_token
    public_token = params['public_token']
    return unless valid_public_token?(public_token)

    response = plaid_client.item.public_token.exchange(public_token)
    PlaidCredential.create!(plaid_item_id: response['item_id'],
                            access_token: response['access_token'],
                            user: current_user)
  end

  private

  def plaid_client
    config = ConfigReader.for('plaid')
    @plaid_client ||= Plaid::Client.new(env:        :sandbox,
                                        client_id:  config['client_id'],
                                        secret:     config['secret'],
                                        public_key: config['public_key'])
  end

  def valid_public_token?(token)
    TOKEN_REGEX =~ token
  end

end
