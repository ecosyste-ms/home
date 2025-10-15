class CreateInvoices < ActiveRecord::Migration[8.0]
  def change
    create_table :invoices do |t|
      t.references :account, null: false, foreign_key: true
      t.references :subscription, foreign_key: true

      t.string :stripe_invoice_id
      t.string :number

      t.string :status, null: false
      t.integer :amount_due_cents, null: false, default: 0
      t.integer :amount_paid_cents, null: false, default: 0
      t.string :currency, default: 'usd'

      t.datetime :period_start
      t.datetime :period_end
      t.datetime :due_date
      t.datetime :paid_at

      t.text :hosted_invoice_url
      t.text :invoice_pdf_url

      t.json :metadata
      t.json :data

      t.timestamps
    end

    add_index :invoices, :stripe_invoice_id, unique: true
    add_index :invoices, :status
    add_index :invoices, :due_date
    add_index :invoices, :number, unique: true
  end
end
