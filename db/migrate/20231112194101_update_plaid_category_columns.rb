class UpdatePlaidCategoryColumns < ActiveRecord::Migration[7.1]
  def change
    remove_index :plaid_categories, :category_id

    remove_column :plaid_categories, :hierarchy
    remove_column :plaid_categories, :category_id

    add_column :plaid_categories, :primary_category, :string
    add_column :plaid_categories, :detailed_category, :string
    add_column :plaid_categories, :description, :string
  end
end
