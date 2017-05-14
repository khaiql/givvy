class CreateInitStructure < ActiveRecord::Migration[5.1]
  def change
    create_table :users do |t|
      t.string :username, null: false
      t.string :display_name
      t.string :email, null: true
      t.string :external_id
      t.integer :allowance, null: false, default: 0
      t.integer :balance, null: false, default: 0
      t.string :avatar_url
      t.string :avatar_hash
      t.boolean :active, null: false, default: true
      t.timestamps
    end

    add_index :users, :username, unique: true

    create_table :rewards do |t|
      t.string :name, null: false
      t.string :image_url
      t.integer :cost, null: false
      t.integer :stock_count
      t.boolean :visible, null: false, default: true
      t.timestamps
    end

    create_table :groups do |t|
      t.string :name, null: false
      t.string :tags, array: true
      t.string :slack_channel
      t.boolean :default, null: false, default: false
      t.timestamps
    end

    create_table :transactions do |t|
      t.references :sender, index: true, foreign_key: { to_table: :users }
      t.references :recipient, index: true, foreign_key: { to_table: :users }
      t.integer :amount
      t.string :message
      t.string :tags, array: true
      t.integer :transaction_type, null: false, default: 0
      t.references :reward
      t.references :group
      t.timestamps
    end

  end
end
