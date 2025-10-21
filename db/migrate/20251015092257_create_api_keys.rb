class CreateApiKeys < ActiveRecord::Migration[8.0]
  def change
    create_table :api_keys do |t|
      t.references :account, null: false, foreign_key: true

      t.string :name, null: false
      t.string :key_hash, null: false
      t.string :key_prefix, null: false

      t.datetime :last_used_at
      t.datetime :expires_at
      t.datetime :revoked_at

      t.json :metadata

      t.timestamps
    end

    add_index :api_keys, :key_hash, unique: true
    add_index :api_keys, :key_prefix
    add_index :api_keys, :revoked_at
  end
end
