class SerialInvoice < ActiveRecord::Migration
  def up
    execute <<-SQL
      create table serial_invoices (clavis_invoice_id integer PRIMARY KEY,
                                     total_amount money,
                                     serial_list_id integer NOT NULL REFERENCES serial_lists on update cascade);
    SQL
  end

  def down
    drop_table :serial_invoices
  end
end
