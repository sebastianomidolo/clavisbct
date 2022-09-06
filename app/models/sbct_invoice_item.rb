class SbctInvoiceItem < ActiveRecord::Base
  self.table_name='sbct_acquisti.invoice_items'

  belongs_to :sbct_invoice
end
