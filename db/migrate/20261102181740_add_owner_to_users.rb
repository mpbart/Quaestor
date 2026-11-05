# frozen_string_literal: true

class AddOwnerToUsers < ActiveRecord::Migration[8.1]
  def change
    add_reference :users, :owner, foreign_key: { to_table: :users }
  end
end
