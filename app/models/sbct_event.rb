# coding: utf-8

class SbctEvent < ActiveRecord::Base
  self.table_name='sbct_acquisti.events'

  attr_accessible :description, :name, :event_type_id, :event_start, :event_end, :title_words
  attr_accessor :title_words

  belongs_to :sbct_event_type, foreign_key:'event_type_id'
  belongs_to :creator, class_name: 'User', foreign_key: :created_by
  belongs_to :updater, class_name: 'User', foreign_key: :updated_by
  
  #has_and_belongs_to_many(:sbct_titles, join_table:'sbct_acquisti.l_events_titles',
  #                        :foreign_key=>'event_id',
  #                        :association_foreign_key=>'id_titolo')

  has_and_belongs_to_many(:sbct_l_event_titles,join_table:'sbct_acquisti.l_events_titles',
                          :foreign_key=>'event_id',
                          :association_foreign_key=>[:event_id, :id_titolo])
  has_many :sbct_titles, :through=>:sbct_l_event_titles


  
  validates :event_type_id, presence: true
  validates :name, presence: true

  before_save :add_timestamp

  def to_label
    self.name
  end

  def owned_by(u)
    # puts "Verifico se l'evento #{self.id} è gestibile da user #{u.id}"
    return false if u.nil?
    [self.created_by,self.updated_by].include?(u.id)
  end
  def owners
    sql = %Q{select u1.email as creator, u2.email as updater from sbct_acquisti.events e
           left join public.users u1 on (u1.id=e.created_by)
           left join public.users u2 on (u2.id=e.updated_by) where e.event_id=#{self.id}}
    r=self.connection.execute(sql).to_a.first
    [r['creator'],r['updater']].uniq.join(',')
  end

  def add_timestamp
    if self.date_created.nil?
      self.date_created = Time.now 
    else
      self.date_updated = Time.now
    end
  end

  def validate_all(user)
    self.sbct_l_event_titles.each do |e|
      # puts "esame: #{e.id} - #{e.validated} (#{e.validated==false})"
      next if e.validated?
      e.validating_now=true
      e.validated_by=user.id
      e.validated=true
      e.date_validated=Time.now
      # puts "save: #{e.id}"
      e.save
    end
    nil
  end

  def close_all(user)
    self.sbct_l_event_titles.each do |e|
      next if e.closed?
      e.closed=true
      e.updated_by=user.id
      e.date_updated=Time.now
      nt = "Chiuso da #{user.email}"
      e.response_note = e.response_note.blank? ? nt : "#{e.response_note}. #{nt}"
      #e.response_note = nt
      e.save
    end
    nil
  end
  def open_all(user)
    self.sbct_l_event_titles.each do |e|
      next if !e.closed?
      e.closed=false
      e.updated_by=user.id
      e.date_updated=Time.now
      nt = "Aperto da #{user.email}"
      e.response_note = e.response_note.blank? ? nt : "#{e.response_note}. #{nt}"
      #e.response_note = nt
      e.save
    end
    nil
  end

  
  def SbctEvent.tutti(sbct_event, params={}, user=nil)

    cond1 = []
    cond2 = []
    cond1 << "e.event_type_id = #{self.connection.quote(sbct_event.event_type_id)}" if !sbct_event.event_type_id.blank?
    cond1 << "#{user.id} in (e.created_by,e.updated_by)" if params[:myevents]=='S'

    cond1 << "et.event_id=#{params[:event_id].to_i}" if params[:event_id].to_i > 0
    case params[:rstatus]
    when '0' # Nessuna richiesta di titoli presente per questo evento
      cond1 << "et.validated is null and et.id_titolo is null"
    when '1' # Nuove, in attesa di convalida
      cond1 << "et.validated is null and et.id_titolo is not null"
    when '2' # (non usato) Convalidate da ufficio acquisti (e ancora non richieste da nessuno) e non chiuse"
      cond1 << "et.validated is true and et.closed is false"
      cond2 << "selected_items_cnt = 0"
    when '3' # Non convalidate e non chiuse
      cond1 << "et.validated is false and et.closed is false"
    when '4' # Convalidate da Ufficio Acquisti
      cond1 << "et.validated is true and et.closed is false"
      # cond2 << "selected_items_cnt > 0 and requested_items_cnt!=selected_items_cnt"
    when '5' # Chiuse
      # cond1 << "et.validated is true"
      cond2 << "requested_items_cnt=selected_items_cnt or closed"
    end

    if !sbct_event.title_words.blank?
      ts=SbctEvent.connection.quote_string(sbct_event.title_words)
      cond1 << %Q{#{SbctEvent.fulltext_attributes} @@ plainto_tsquery('simple', '#{ts}')}
    end

    if params[:rstatus].blank? and sbct_event.title_words.blank?
      cond2 << "closed is false" if params[:event_id].blank?
    end

    cond1 = cond1.size==0 ? '' : "WHERE true AND #{cond1.join(' and ')}"
    cond2 = cond2.size==0 ? '' : "WHERE true AND #{cond2.join(' and ')}"
    sql = %Q{with t1 AS
      (SELECT DISTINCT e.event_id,et.id_titolo,t.titolo,t.ean,et.closed,et.notes,e.description,
        e.name,e.event_start,e.event_end,u.email as creato_da,et.request_date,et.response_note,
    case when u.id in (e.created_by,e.updated_by) then true else false end as editable,
    e.event_type_id,
    case
       when t is null then NULL
       when et.validated is null then 'da convalidare'
       when et.validated = true then 'convalidato'
       else 'non convalidato'
    end as stato_convalida,
     count(et.id_titolo) over (partition by et.event_id) as numtitoli,
     et.numcopie as requested_items_cnt,
  copie.selected_items_cnt

from sbct_acquisti.events e
  left join public.users u on(u.id=e.created_by)
  left join sbct_acquisti.l_events_titles et using(event_id)
  left join sbct_acquisti.titoli t on(t.id_titolo=et.id_titolo)

  LEFT JOIN LATERAL
    (select count(id_copia) as selected_items_cnt
     FROM sbct_acquisti.copie cp WHERE cp.event_id = et.event_id and cp.id_titolo = et.id_titolo)
     as copie on true
  #{cond1}
  )
  SELECT * FROM t1
  #{cond2}
  order by titolo}

    fd=File.open("/home/seb/sbct_events.sql", "w")
    fd.write(sql)
    fd.close
    SbctEvent.find_by_sql(sql)
  end

  def SbctEvent.label_select(params={},user=nil)
    sql=%Q{select e.event_id as key,e.name as label from sbct_acquisti.events e order by e.name;}
    res = []
    self.connection.execute(sql).to_a.each do |r|
      label = r['label']
      res << [label,r['key']]
    end
    res
  end

  def SbctEvent.fulltext_attributes
    %Q{ (to_tsvector('simple', coalesce(titolo, ''))    ||
         to_tsvector('simple', coalesce(ean, ''))    ||
         to_tsvector('simple', coalesce(event_type_id, ''))    ||
         to_tsvector('simple', coalesce(name, ''))
         ) }
  end


  
end
