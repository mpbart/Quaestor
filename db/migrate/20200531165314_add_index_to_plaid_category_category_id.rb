class AddIndexToPlaidCategoryCategoryId < ActiveRecord::Migration[6.0]
  def change
    add_index :plaid_categories, :category_id
  end
end
