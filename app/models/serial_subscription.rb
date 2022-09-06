# coding: utf-8
class SerialSubscription < ActiveRecord::Base
  self.primary_keys = :serial_title_id, :library_id
  attr_accessible :serial_title_id,:library_id,:prezzo,:note,:numero_copie
  before_save :set_date_updated
  
  belongs_to :serial_title
  belongs_to :clavis_library, foreign_key: :library_id

  def set_date_updated
    self.date_updated=Time.now
  end

  def serial_invoices
    sql = %Q{
        select * from serial_l_invoices l join serial_invoices i on(i.clavis_invoice_id=l.invoice_id)
          join clavis.invoice ci on(ci.invoice_id=i.clavis_invoice_id) where l.title_id=#{self.serial_title_id}
          and l.library_id=#{self.library_id};
    }
    SerialInvoice.find_by_sql(sql).to_a
  end

  def library_select
    sql = %Q{
       select cl.library_id,cl.label,s.numero_copie,s.tipo_fornitura
       from serial_subscriptions s join clavis.library cl using(library_id) where serial_title_id = #{self.serial_title_id};
    }
    options=self.connection.execute(sql).to_a.collect {|i| ["#{i['label']} (#{i['tipo_fornitura']})",i['library_id']]}
    options
  end

  def SerialSubscription.associa_copie_multiple(libs,nums)
    res=[]
    n=nums.split(',')
    i=0
    libs.split(', ').each do |l|
      res << (n[i].to_i > 1 ? "#{l} (#{n[i]} copie)" : l)
      i+=1
    end
    res.join(', ')
  end

  def SerialSubscription.copie_per_bib(library_id, library_ids, nums)
    res=0, i=0, n=nums.split(',')
    library_ids.split(',').each do |id|
      res = n[i].to_i and break if id.to_i==library_id
      i+=1
    end
    res
  end
end

