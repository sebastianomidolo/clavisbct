class ClavisItem < ActiveRecord::Base
  self.table_name='clavis.item'
  self.primary_key = 'item_id'

  attr_accessible :title, :owner_library_id, :item_status, :opac_visible, :manifestation_id,
  :item_media, :collocation, :inventory_number, :manifestation_dewey,
  :current_container, :in_container

  belongs_to :owner_library, class_name: 'ClavisLibrary', foreign_key: 'owner_library_id'

  has_many :talking_books, :foreign_key=>'n', :primary_key=>'collocation'
  belongs_to :clavis_manifestation, :foreign_key=>:manifestation_id
  has_many :attachments, :as => :attachable


  def to_label
    if self.clavis_manifestation.nil?
      self.la_collocazione
    else
      "#{self.la_collocazione} (#{self.clavis_manifestation.title.strip})"
    end
  end

  def view
    extra = self['value_label'].nil? ? '' : "#{self['value_label']}: "
    "#{extra}#{self.title.strip}#{self.la_collocazione}"
  end

  def inventario
    return 'fuori catalogo' if self.manifestation_id==0
    "#{inventory_serie_id}-#{inventory_number}"
  end

  def consistency_notes
    coll=self.connection.quote(self.collocation)
    where="manifestation_id=#{self.manifestation_id} AND library_id=#{self.owner_library_id}"
    sql=%Q{SELECT * FROM clavis.consistency_note WHERE #{where}
         AND collocation = #{coll}}
    r=ClavisConsistencyNote.find_by_sql(sql)
    return r if r.size==1
    sql=%Q{SELECT * FROM clavis.consistency_note WHERE #{where}
       AND collocation ~* #{coll} ORDER BY consistency_note_id}
    r=ClavisConsistencyNote.find_by_sql(sql)
    return r if r.size!=0
    sql=%Q{SELECT * FROM clavis.consistency_note WHERE #{where}
       ORDER BY consistency_note_id}
    ClavisConsistencyNote.find_by_sql(sql)
  end

  def la_collocazione
    r=[self.section,self.collocation,self.specification,self.sequence1,self.sequence2]
    r.delete_if {|a| a.blank?}
    r.join('.')
  end

  def collocazione
    r=[self.section,self.collocation,self.specification,self.sequence1,self.sequence2]
    r.delete_if {|a| a.blank?}
    r.join('.')
  end

  def current_container
    @current_container
  end

  def current_container= value
    return nil if value.nil?
    @current_container=value.upcase.gsub(' ','')
  end

  def in_container
    @in_container
  end

  def in_container= value
    @in_container=value
  end

  def save_in_google_drive(ws)
    data=[]
    title=self.title.strip
    if self.item_media=='S'
      self.consistency_notes.each do |cn|
        cn_colloc=cn.collocation==self.collocazione ? '' : cn.collocation
        data << [self.current_container,self.collocazione,self.inventario,title,self.manifestation_id,self.item_id,cn.consistency_note_id,cn.text_note,cn_colloc,(cn.closed.to_i==1 ? 'Consistenza CHIUSA' : 'Consistenza APERTA')]
      end
    else
      data << [self.current_container,self.collocazione,self.inventario,title,self.manifestation_id,self.item_id]
    end
    ws.update_cells(ws.num_rows+1,1,data)
  end

  def clavis_url(mode=:show)
    ClavisItem.clavis_url(self.id,mode)
  end

  def self.clavis_url(item_id,mode=:show)
    config = Rails.configuration.database_configuration
    host=config[Rails.env]['clavis_host']
    r=''
    if mode==:show
      r="#{host}/index.php?page=Catalog.ItemViewPage&id=#{item_id}"
    end
    if mode==:edit
      r="#{host}/index.php?page=Catalog.ItemInsertPage&id=#{item_id}"
    end
    if mode==:loan
      r="#{host}/index.php?page=Circulation.NewLoan&itemId=#{item_id}"
    end
    r
  end

  def self.item_status
    sql=%Q{select value_label as label,value_key as key from clavis.lookup_value lv
  where value_language = 'it_IT' and value_class='ITEMSTATUS' order by value_key}
    self.connection.execute(sql).collect {|i| ["#{i['key']} - #{i['label']}",i['key']]}
  end

  def self.item_media
    sql=%Q{select value_label as label,value_key as key from clavis.lookup_value lv
  where value_language = 'it_IT' and value_class='ITEMMEDIATYPE' order by value_key}
    self.connection.execute(sql).collect {|i| ["#{i['key']} - #{i['label']}",i['key']]}
  end

  def self.owner_library
    sql=%Q{select library_id as key,label from clavis.library
      where library_status='A' AND library_internal='1' order by label}
    puts sql
    self.connection.execute(sql).collect {|i| [i['label'],i['key']]}
  end
  def self.periodici_e_fatture(library_id,issue_years)
    issue_years=[issue_years] if issue_years.class==String
    years=(issue_years.collect {|x| "'#{x}'"}).join(',')
    sql=%Q{SELECT issue_year,ci.manifestation_id,cm.title,ec.id as excel_cell_id,
   array_to_string(array_agg(ci.item_id || ' ' || ci.issue_status || ' ' ||
     case when i.invoice_id is null then 0 else i.invoice_id end), ',') as info_fattura
 FROM clavis.manifestation cm JOIN clavis.item ci USING (manifestation_id)
    LEFT JOIN clavis.invoice i USING(invoice_id)
    LEFT JOIN public.excel_cells ec ON (cell_content=cm."ISBNISSN"
     AND excel_sheet_id=26 and cell_column='_K')
 WHERE ci.owner_library_id = #{library_id} AND ci.issue_year IN(#{years})
  AND issue_id NOTNULL
  GROUP BY ci.issue_year,ci.manifestation_id,cm.sort_text,cm.title,ec.id
  ORDER BY ci.issue_year,cm.sort_text;}
    puts sql
    self.connection.execute(sql).to_a
  end

end
