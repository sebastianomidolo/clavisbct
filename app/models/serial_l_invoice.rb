class SerialLInvoice < ActiveRecord::Base
  self.primary_key = 'clavis_invoice_id'
  self.primary_keys = :invoice_id, :library_id, :title_id

  #has_many :serial_invoices
  #has_many :clavis_invoices, :through=>:serial_invoices


end
