# coding: utf-8
class SbctSupplier < ActiveRecord::Base
  self.table_name='sbct_acquisti.suppliers'
  self.primary_key = 'supplier_id'
  attr_accessible :supplier_name, :supplier_id
  has_many :sbct_items, foreign_key:'supplier_id'
  has_many :sbct_budgets, foreign_key:'supplier_id'
  belongs_to :clavis_supplier, foreign_key:'supplier_id'

  def to_label
    "#{self.supplier_name} (id: #{self.id})"
  end

  def libraries
    sql = %Q{
select lc.label,cl.library_id,cl.shortlabel as library_name,sum(numcopie) as numcopie, sum(c.prezzo*c.numcopie) as importo,
   o.label as order_status
from sbct_acquisti.suppliers s join sbct_acquisti.copie c using(supplier_id)
  join sbct_acquisti.library_codes lc on(lc.clavis_library_id=c.library_id)
  join clavis.library cl on(cl.library_id=c.library_id)
  join sbct_acquisti.order_status o on(o.id = c.order_status)
  where s.supplier_id=#{self.id}
  group by lc.label,cl.library_id,cl.shortlabel,o.label order by lc.label;}   
    puts sql
    ClavisLibrary.find_by_sql(sql)
  end

  def SbctSupplier.tutti(params={})
    cond = []
    cond << "s.supplier_name ~ #{self.connection.quote(params[:pattern])}" if !params[:pattern].blank?
    cond << "c.order_status = #{self.connection.quote(params[:order_status])}" if !params[:order_status].blank?
    cond << "s.supplier_id=#{self.connection.quote(params[:supplier_id])}" if !params[:supplier_id].blank?
    cond = cond.size==0 ? '' : "WHERE #{cond.join(' AND ')}"
    sql=%Q{select s.supplier_name, s.supplier_id, cs.discount, sum(c.numcopie) as numero_copie,
COALESCE((sum(c.prezzo * c.numcopie)),0) as impegnato,
to_char(avg(c.prezzo), 'FM999999999.00') as costo_medio
FROM sbct_acquisti.suppliers s join clavis.supplier cs using(supplier_id) left join sbct_acquisti.copie c
using(supplier_id) left join sbct_acquisti.titoli t using(id_titolo)
#{cond} group by s.supplier_name,s.supplier_id, cs.discount
order by s.supplier_name;
    }
    puts sql
    SbctSupplier.find_by_sql(sql)
  end

  def SbctSupplier.quota_fornitore(pattern_fornitore, pattern_budget)
    sql=%Q{select (sum(total_amount)/(select count(*) from sbct_acquisti.suppliers where supplier_name ~ '^#{pattern_fornitore}'))::numeric(10,2)
             as "quota_per_fornitore" from sbct_acquisti.budgets where label ~ '^#{pattern_budget}';}
    self.connection.execute(sql).first['quota_per_fornitore'].to_f
  end

end
