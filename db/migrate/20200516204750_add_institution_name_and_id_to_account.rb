class AddInstitutionNameAndIdToAccount < ActiveRecord::Migration[6.0]
  def change
    add_column :accounts, :institution_name, :string
    add_column :accounts, :institution_id, :string
  end
end
