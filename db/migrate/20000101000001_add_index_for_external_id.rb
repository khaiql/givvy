class AddIndexForExternalId < ActiveRecord::Migration[5.1]
  def change
    add_index :users, :external_id
  end
end
