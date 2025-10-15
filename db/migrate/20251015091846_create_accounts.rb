class CreateAccounts < ActiveRecord::Migration[8.0]
  def change
    create_table :accounts do |t|
      t.string :name, null: false
      t.string :email, null: false
      t.boolean :show_profile_picture, default: true
      t.string :profile_picture_url

      t.string :stripe_customer_id
      t.string :payment_method_type
      t.string :payment_method_last4
      t.string :payment_method_expiry
      t.string :collection_method
      t.integer :days_until_due

      t.string :status, default: 'active'
      t.datetime :suspended_at
      t.datetime :deleted_at

      t.boolean :admin, default: false, null: false

      t.timestamps
    end

    add_index :accounts, :email, unique: true
    add_index :accounts, :stripe_customer_id, unique: true
    add_index :accounts, :deleted_at
    add_index :accounts, :admin
  end
end
