class CreateIdentities < ActiveRecord::Migration[8.0]
  def change
    create_table :identities do |t|
      t.references :account, null: false, foreign_key: true

      t.string :provider, null: false
      t.string :uid, null: false
      t.string :email
      t.string :username
      t.string :name
      t.string :avatar_url

      t.text :token
      t.text :refresh_token
      t.datetime :token_expires_at

      t.json :data

      t.timestamps
    end

    add_index :identities, [:provider, :uid], unique: true
  end
end
