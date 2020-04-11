class PlaidController < ActionController::Base
  def get_access_token(params)
    p params
    PlaidCredentials.store!(params)
  end
end
