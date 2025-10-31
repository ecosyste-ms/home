class AddUuidToPlans < ActiveRecord::Migration[8.1]
  def up
    # Enable pgcrypto extension for UUID generation
    enable_extension 'pgcrypto' unless extension_enabled?('pgcrypto')

    # Add UUID column with default value
    add_column :plans, :uuid, :uuid, default: 'gen_random_uuid()', null: false

    # Add unique index
    add_index :plans, :uuid, unique: true
  end

  def down
    remove_index :plans, :uuid
    remove_column :plans, :uuid
  end
end
