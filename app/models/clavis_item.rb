class ClavisItem < ActiveRecord::Base
  self.table_name='clavis.item'
  self.primary_key = 'item_id'

  attr_accessible :title, :owner_library_id, :item_status, :opac_visible, :manifestation_id,
                   :item_media, :collocation, :inventory_number, :manifestation_dewey

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
    "#{inventory_serie_id}-#{inventory_number}"
  end

  def la_collocazione
    r=[self.section,self.collocation,self.specification,self.sequence1,self.sequence2]
    r.delete_if {|a| a.blank?}
    r.join('.')
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
