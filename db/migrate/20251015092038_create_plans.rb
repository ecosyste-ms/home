class CreatePlans < ActiveRecord::Migration[8.0]
  def change
    create_table :plans do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.string :display_name
      t.string :stripe_price_id
      t.integer :price_cents, null: false, default: 0
      t.string :currency, default: 'usd'
      t.string :billing_period, null: false
      t.integer :requests_per_hour, null: false
      t.text :description
      t.json :features
      t.json :metadata

      t.string :plan_family
      t.integer :version, default: 1
      t.boolean :active, default: true, null: false
      t.boolean :public, default: true, null: false
      t.boolean :visible, default: true
      t.integer :position, default: 0
      t.datetime :deleted_at

      t.timestamps
    end

    add_index :plans, :slug, unique: true
    add_index :plans, :stripe_price_id, unique: true
  end
end
