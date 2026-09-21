# frozen_string_literal: true

require 'rails_helper'
require 'stringio'

RSpec.describe 'Rails 8 compatibility' do
  it 'boots with the intended framework and Ruby versions' do
    expect(Rails.version).to eq('8.1.3.1')
    expect(RUBY_VERSION).to eq('3.4.10')
  end

  it 'stores CSV attachments with the configured Active Storage metadata' do
    user = create(:user)

    user.transaction_csvs.attach(
      io:           StringIO.new("Date,Description\n01/01/2026,Test\n"),
      filename:     'transactions.csv',
      content_type: 'text/csv'
    )

    blob = user.transaction_csvs.attachments.last.blob
    expect(blob.service_name).to eq('test')
    expect(ActiveStorage::VariantRecord.table_exists?).to be(true)
  end
end
