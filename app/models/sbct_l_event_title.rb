# coding: utf-8
class SbctLEventTitle < ActiveRecord::Base
  self.table_name = 'sbct_acquisti.l_events_titles'
  self.primary_keys = [:event_id,:id_titolo]

  attr_accessible :numcopie, :notes, :event_id, :id_titolo, :validated, :response_note, :validated_by, :date_validated, :closed
  attr_accessor :validating_now

  validates_inclusion_of :numcopie, :in => 1..20
  

  belongs_to :sbct_title, :foreign_key=>'id_titolo'
  belongs_to :sbct_event, :foreign_key=>'event_id'

  before_save :add_timestamp

  def numero_copie_selezionabili
    # i=self.connection.execute("select count(*) as cnt from sbct_acquisti.copie where id_titolo=#{self.id_titolo}").to_a.first['cnt'].to_i
    sql = %Q{with t1 as
(select et.numcopie,count(cp) as selected
  from sbct_acquisti.l_events_titles et left join sbct_acquisti.copie cp on(cp.event_id=et.event_id AND cp.id_titolo=et.id_titolo)
  where et.id_titolo=#{self.id_titolo} AND et.event_id=#{self.event_id} group by 1)
 select numcopie - selected as  residue from t1;}
    self.connection.execute(sql).first['residue'].to_i
  end

  def stato_convalida
    c = self.validated.class
    m = '???'
    m = 'convalidata'     if c == TrueClass
    m = 'NON convalidata' if c == FalseClass
    "#{m} - #{self.response_note}"
  end

  def add_timestamp
    self.response_note = nil if self.response_note.blank?
    if self.validating_now=='t'
      self.date_validated = Time.now
      #if self.validated == true
      #  self.date_validated = Time.now
      #else
      #  self.validated_by = nil
      #  self.date_validated = nil
      #end
    else
      self.date_updated = Time.now
    end
  end

  def SbctLEventTitle.richieste_aperte_per_titolo(id_titolo)
    sql = "SELECT et.* FROM sbct_acquisti.l_events_titles et join sbct_acquisti.events e USING(event_id) WHERE et.validated is true and et.closed is false and et.id_titolo=#{id_titolo}"
    self.find_by_sql(sql)  
  end

  def SbctLEventTitle.nuovi?
    i=self.connection.execute("select count(*) from sbct_acquisti.l_events_titles where validated is null").first['count'].to_i
    i > 0 ? true : false
  end

  def SbctLEventTitle.titoli_selezionabili?
    sql=%Q{with t1 AS
(
 SELECT et.numcopie as requested_items_cnt,copie.selected_items_cnt
  FROM sbct_acquisti.events e left join sbct_acquisti.l_events_titles et using(event_id)
   LEFT JOIN LATERAL
    (select count(id_copia) as selected_items_cnt
     FROM sbct_acquisti.copie cp WHERE cp.event_id = et.event_id and cp.id_titolo = et.id_titolo)
     as copie on true
  WHERE et.validated is true and et.closed is false
)
SELECT count(*) FROM t1 where selected_items_cnt < requested_items_cnt}
    # i=self.connection.execute("select count(*) from sbct_acquisti.l_events_titles where validated is not null and closed is false").first['count'].to_i
    i=self.connection.execute(sql).first['count'].to_i
    i > 0 ? true : false
  end
  
  def SbctLEventTitle.status_select
    [
      ['(nessuna richiesta di titoli)', 0],
      ['Nuove, in attesa di convalida', 1],
      ['Convalidate da Ufficio Acquisti', 4],
      ['Non convalidate', 3],
      ['Chiuse', 5],
    ]
  end
  
end

