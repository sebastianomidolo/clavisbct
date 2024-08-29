class ClavisSupplier < ActiveRecord::Base
  self.table_name='clavis.supplier'
  self.primary_key = 'supplier_id'

  has_many :clavis_invoices, foreign_key: 'invoice_id'

  def clavis_items_count
    sql = "select count(item_id) from clavis.item where supplier_id = #{self.id}"
    self.connection.execute(sql).to_a.first['count'].to_i
  end

  def items_mai_prestati
    return (self.clavis_items_count - self.items_prestati_almeno_una_volta.size)
    sql = %Q{SELECT ci.title,ci.item_id FROM clavis.item ci left join clavis.loan cl using(item_id)
        left join prestiti p on(p.patron_id=cl.patron_id) WHERE ci.supplier_id=#{self.id} and cl is null}
    self.connection.execute(sql).to_a.size
  end

  def items_prestati_almeno_una_volta
    sql = %Q{SELECT DISTINCT ci.item_id FROM clavis.item ci join clavis.loan cl using(item_id)
         join prestiti p on(p.patron_id=cl.patron_id) WHERE ci.supplier_id=#{self.id}}
    self.connection.execute(sql).to_a    
  end

  def ClavisSupplier.clavis_url(id)
    config = Rails.configuration.database_configuration
    host=config[Rails.env]['clavis_host']
    "#{host}/index.php?page=Acquisition.SupplierPage&supplierId=#{id}"
  end


end

