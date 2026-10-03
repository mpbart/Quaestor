# frozen_string_literal: true

require 'rails_helper'
require 'query_builder'

RSpec.describe QueryBuilder do
  describe '.build_where' do
    it 'builds a predicate for an allowlisted filter' do
      where_clause = described_class.build_where(
        ActionController::Parameters.new(q: 'groceries').permit!
      )

      expect(where_clause).to be_a(Arel::Nodes::Matches)
    end

    it 'ignores unknown parameter names' do
      where_clause = described_class.build_where(
        ActionController::Parameters.new('__send__' => 'system').permit!
      )

      expect(where_clause).to be_nil
    end
  end
end
