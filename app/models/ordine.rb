class Ordine < ActiveRecord::Base
  self.table_name='serials_admin_table'
  attr_accessible :titolo, :library_id, :ordanno, :numero_fattura, :issue_status

  attr_accessor :issue_status

  belongs_to :clavis_library, :foreign_key=>:library_id
  belongs_to :clavis_manifestation, :foreign_key=>:manifestation_id

  def Ordine.fatture(library_id)
    sql=%Q{select numero_fattura,data_emissione,data_pagamento,
  sum(prezzo::float) as totale_fattura,count(*) as numero_titoli
  from serials_admin_table
  where library_id=#{library_id} and numero_fattura is not null
  group by numero_fattura,data_emissione,data_pagamento
  order by data_emissione,numero_fattura}
    Ordine.connection.execute(sql).to_a
  end
end
