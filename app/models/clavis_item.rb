# -*- coding: utf-8 -*-
class ClavisItem < ActiveRecord::Base
  self.table_name='clavis.item'
  self.primary_key = 'item_id'

  attr_accessible :title, :owner_library_id, :item_status, :opac_visible, :manifestation_id,
  :item_media, :collocation, :inventory_number, :manifestation_dewey,
  :current_container, :in_container, :dewey_collocation,
  :home_library_id, :issue_number, :item_icon, :custom_field3

  belongs_to :owner_library, class_name: 'ClavisLibrary', foreign_key: 'owner_library_id'

  has_many :talking_books, :foreign_key=>'n', :primary_key=>'collocation'
  belongs_to :clavis_manifestation, :foreign_key=>:manifestation_id
  has_many :attachments, :as => :attachable
  has_one :open_shelf_item, foreign_key:'item_id'

  def to_label
    if self.clavis_manifestation.nil?
      self.la_collocazione
    else
      "#{self.la_collocazione} (#{self.clavis_manifestation.title.strip})"
    end
  end

  def container
    Container.find_by_label self.current_container
  end

  def view
    extra = self['value_label'].nil? ? '' : "#{self['value_label']}: "
    "#{extra}#{self.title.strip}#{self.la_collocazione}"
  end

  def inventario
    # return 'fuori catalogo' if self.manifestation_id==0
    "#{inventory_serie_id}-#{inventory_number}"
  end

  def consistency_notes
    coll=self.connection.quote(self.collocation)
    where="manifestation_id=#{self.manifestation_id} AND library_id=#{self.owner_library_id}"
    sql=%Q{SELECT * FROM clavis.consistency_note WHERE #{where}
         AND collocation = #{coll}}
    puts sql
    r=ClavisConsistencyNote.find_by_sql(sql)
    return r if r.size==1
    sql=%Q{SELECT * FROM clavis.consistency_note WHERE #{where}
       AND collocation ~* #{coll} ORDER BY consistency_note_id}
    begin
      r=ClavisConsistencyNote.find_by_sql(sql)
    rescue
    end
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

  def dewey_collocation
    return @dewey_collocation if !@dewey_collocation.nil?
    return nil if self.id.nil?
    r=self.connection.execute("select dewey_collocation as c from ricollocazioni where item_id = #{self.id}").to_a
    r.size==0 ? nil : r.first['c']
  end

  def dewey_collocation= value
    @dewey_collocation=value
  end

  def save_in_container(user,container)
    old_container=ContainerItem.find_by_item_id(self.id)
    return "già presente in #{old_container.container.label}" if !old_container.nil?
    return "contenitore #{container.label} chiuso, elemento non aggiunto" if container.closed?
    title=self.title.strip
    container_item = ContainerItem.new(
                                       created_by:user.id,
                                       manifestation_id:self.manifestation_id,
                                       item_title:title,
                                       container_id:container.id,
                                       item_id:self.item_id
                                       )
    container_item.save
    return "(#{container.label} contiene #{container.container_items.size} elementi)"
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

  def ClavisItem.items_ricollocati(params)
    cond=[]
    dewey=params[:dewey_collocation]
    s = params[:sections].blank? ? [] : params[:sections].collect {|x| ClavisItem.connection.quote x}
    cond << "section in (#{s.join(',')})" if s.size>0
    if !dewey.blank?
      if (/^[0-9]/ =~ dewey)==0
        cond << "dewey_collocation ~ '^#{dewey}'"
      else
        ts=ClavisItem.connection.quote_string(dewey.split.join(' & '))
        cond << "to_tsvector('simple', item.title) @@ to_tsquery('simple', '#{ts}')"
      end
    end
    joincond='left join'
    if params[:onshelf]=='yes'
      cond << 'item.openshelf=true'
      joincond='join'
      cond << "os.os_section=#{ClavisItem.connection.quote(params[:dest_section])}" if !params[:dest_section].blank?
    end
    cond << "r.class_id=#{ClavisItem.connection.quote(params[:class_id])}" if !params[:class_id].nil?
    cond << 'false' if cond==[]
    if params[:formula]=='1'
      cond << "item.loan_class='B' AND item.opac_visible='0' AND item.item_status='F' AND cit.item_id IS NULL AND item.item_media!='S' AND item.loan_status='A'"
    end
    cond << "cc.collocazione ~* #{ClavisItem.connection.quote(params[:collocation])}" if !params[:collocation].blank?

    cond = cond.join(' AND ')
    order_by = params[:sort] == 'dewey' ? 'r.sort_text' : 'cm.edition_date desc, cc.sort_text'

    ClavisItem.paginate(:conditions=>cond,:page=>params[:page], :per_page=>100,
                                        :select=>"os.item_id as open_shelf_item_id, item.item_id,
            item.inventory_serie_id || '-' || item.inventory_number as serieinv,
            item.inventory_serie_id,item.inventory_number,item.usage_count,item.item_status,
              item.title as title,cm.edition_date,cm.publisher,cm.manifestation_id,
            ist.value_label as item_status, lst.value_label as loan_status,
            item.opac_visible, cit.label as contenitore,
             ca.full_text as descrittore,r.dewey_collocation,cc.collocazione as full_collocation",
                                        :joins=>"join clavis.manifestation cm using(manifestation_id)
             join ricollocazioni r using(item_id) join clavis.collocazioni cc using(item_id)
             join clavis.authority ca on(ca.authority_id=r.class_id)
             join clavis.lookup_value ist on(ist.value_class='ITEMSTATUS' and ist.value_key=item_status
                 and ist.value_language='it_IT')
             join clavis.lookup_value lst on(lst.value_class='LOANSTATUS' and lst.value_key=loan_status
                 and lst.value_language='it_IT')
             left join container_items cit on(cit.item_id=item.item_id)
             #{joincond} open_shelf_items os on (r.item_id=os.item_id)",
                                        :order=>order_by)
  end

end
