# coding: utf-8
class ClavisLibrary < ActiveRecord::Base
  self.table_name='clavis.library'
  self.primary_key = 'library_id'

  attr_accessible :library_id

  has_many :owned_items, class_name: 'ClavisItem', foreign_key: 'owner_library_id'
  has_many :ordini, foreign_key: 'library_id'
  has_many :timetables, class_name: 'ClavisLibraryTimetable', foreign_key: 'library_id'
  has_many :containers, foreign_key: 'library_id'
  has_many :sbct_items, foreign_key: 'library_id'
  has_many :bib_sections, foreign_key: 'library_id'


  has_and_belongs_to_many(:sbct_l_budget_libraries,join_table:'sbct_acquisti.l_budgets_libraries',
                          :foreign_key=>'clavis_library_id',
                          :association_foreign_key=>[:budget_id, :clavis_library_id])
  has_many :sbct_budgets, :through=>:sbct_l_budget_libraries
  
  def to_label
    self.label[0..40]
  end
  def nice_description
    self.description[5..100]
  end

  def clavis_url
    ClavisLibrary.clavis_url(self.id)
  end

  def week_timetable
    date  = Date.parse('Monday')
    self.timetables.where("timetable_day>='#{date.strftime('%F')}'").limit(7).order('timetable_day')
  end

  def collocation_sections_select(filter=nil)
    cond = filter.nil? ? '' : "AND value_key ~ #{self.connection.quote(filter)}"
    sql=%Q{select value_key as key,value_label as label from clavis.library_value where value_library_id=#{self.id} #{cond}}
    self.connection.execute(sql).collect {|i| [i['label'],i['key']]}
  end
  
  def inventory_serie_select
    sql=%Q{select inventory_serie_id as key,description as d
              from clavis.inventory_serie where library_id = #{self.id} order by inventory_serie_id;}
    self.connection.execute(sql).collect do |i|
      label = ( i['d'].blank? or i['d']==i['key'] ) ? i['key'] : "#{i['key']} - #{i['d']}"
      [i['key'],label]
    end
  end

  def siglabct
    s=ClavisLibrary.siglebct.key(self.id)
    return nil if s.nil?
    s.to_s.upcase
  end

  def ClavisLibrary.clavis_url(id)
    config = Rails.configuration.database_configuration
    host=config[Rails.env]['clavis_host']
    "#{host}/index.php?page=Library.LibraryViewPage&id=#{id}"
  end

  def ClavisLibrary.library_select(kl_order='kl')
    sql=%Q{select library_id as key,label from clavis.library
      where library_internal='1' order by label}
    if kl_order=='kl'
      self.connection.execute(sql).collect {|i| [i['key'],i['label']]}
    else
      self.connection.execute(sql).collect {|i| [i['label'],i['key']]}
    end
  end

  def ClavisLibrary.library_ids_to_siglebct(library_ids)
    if library_ids.class == Array
      library_ids.collect {|id| ClavisLibrary.siglabct(id.to_i)}
    else
      library_ids.split(',').collect {|id| ClavisLibrary.siglabct(id.to_i)}
    end
  end

  def ClavisLibrary.siglabct(library_id)
    s=ClavisLibrary.siglebct.key(library_id.to_i)
    return "" if s.nil?
    s.to_s.upcase
  end

  def ClavisLibrary.con_siglabct
    self.find_by_sql("select c.label as siglabct,l.* from sbct_acquisti.library_codes c join clavis.library l on(l.library_id=c.clavis_library_id)")
  end

  def ClavisLibrary.siglebct
    sql = %Q{SELECT * FROM sbct_acquisti.library_codes}
    h={}
    self.connection.execute(sql).to_a.each do |r|
      h[r['label'].strip.downcase.to_sym] = r['clavis_library_id'].to_i
    end
    return h
    # Segure vecchio codice non utilizzato:
    {
      a:10,
      b:11,
      bel:4,
      ci:28,
      d:13,
      e:14,
      f:15,
      gin:496,
      h:16,
      i:17,
      l:18,
      m:19,
      man:7,
      mar:8,
      mus:3,
      n:20,
      o:21,
      p:22,
      q:2,
      r:23,
      s:24,
      str:9,
      t:25,
      u:26,
      v:27,
      y:1121,
      z:29,
    }
  end

end
