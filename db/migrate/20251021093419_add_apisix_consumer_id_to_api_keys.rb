class AddApisixConsumerIdToApiKeys < ActiveRecord::Migration[8.0]
  def change
    add_column :api_keys, :apisix_consumer_id, :string
    add_index :api_keys, :apisix_consumer_id, unique: true
  end
end
