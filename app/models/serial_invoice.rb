class SerialInvoice < ActiveRecord::Base
  self.primary_key = 'clavis_invoice_id'
  attr_accessible :clavis_invoice_id, :total_amount, :serial_list_id, :notes
  belongs_to :serial_list
  belongs_to :clavis_invoice, foreign_key: 'clavis_invoice_id'

  has_many :serial_subscriptions

  validates :serial_list_id, presence: true
  validates :total_amount, presence: true
  validates_presence_of :clavis_invoice, message:'La fattura deve esistere in Clavis'

  def to_label
    ci = self.clavis_invoice
    "#{ci.to_label} (#{ci.clavis_supplier.supplier_name})"
  end

  def clavis_url
    ClavisInvoice.clavis_url(self.id)
  end

  def set_titles(titles,selected_titles,library_id)
    # puts "Fattura #{self.id} per biblioteca #{library_id} titles.inspect: #{titles.inspect} - #{selected_titles.inspect}"
    ids = titles - selected_titles
    # puts "ids da non selezionare #{ids.join(',')}"
    if ids==[]
      sql=''
    else
      sql=%Q{
UPDATE serial_subscriptions SET serial_invoice_id=NULL WHERE library_id=#{library_id} AND
                  serial_title_id in (#{ids.join(',')});}
    end
    if selected_titles==[]
      sql2=''
    else
      sql2=%Q{
UPDATE serial_subscriptions SET serial_invoice_id=#{self.id} WHERE library_id=#{library_id} AND
             serial_title_id in (#{selected_titles.join(',')});}
    end
    self.connection.execute(sql+sql2)
    fd=File.open("/home/seb/serial_dbg.txt", "w")
    fd.write(sql+sql2)
    fd.write(titles.inspect)
    fd.close
    true
  end

  def subscriptions
    sql=%Q{select ss.serial_title_id,st.title,sl.nickname as library_name,ss.tipo_fornitura,st.prezzo_stimato,ss.prezzo as prezzo_in_fattura,
            ss.library_id, st.serial_list_id
       from serial_subscriptions ss
        join serial_titles st on(st.id=ss.serial_title_id)
        join serial_libraries sl on(sl.clavis_library_id=ss.library_id and sl.serial_list_id=st.serial_list_id)
        where ss.serial_invoice_id=#{self.id} order by st.sortkey, library_name;}
    puts sql
    SerialSubscription.find_by_sql(sql)
  end

end
