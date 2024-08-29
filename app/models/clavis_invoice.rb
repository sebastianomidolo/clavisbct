class ClavisInvoice < ActiveRecord::Base
  self.table_name='clavis.invoice'
  self.primary_key = 'invoice_id'

  belongs_to :clavis_supplier, foreign_key:'supplier_id'
  has_many :serial_invoices, foreign_key:'clavis_invoice_id'

  def to_label
    "#{self.invoice_number} del #{self.invoice_date}"
  end

  def clavis_url
    ClavisInvoice.clavis_url(self.id)
  end

  def ClavisInvoice.clavis_url(id)
    config = Rails.configuration.database_configuration
    host=config[Rails.env]['clavis_host']
    "#{host}/index.php?page=Acquisition.InvoiceViewPage&id=#{id}"
  end

end

