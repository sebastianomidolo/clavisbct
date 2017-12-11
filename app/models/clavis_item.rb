# -*- coding: utf-8 -*-

include TextSearchUtils


class ClavisItem < ActiveRecord::Base
  self.table_name='clavis.item'
  self.primary_key = 'item_id'

  attr_accessible :title, :owner_library_id, :item_status, :opac_visible, :manifestation_id,
  :item_media, :section, :collocation, :inventory_number, :inventory_serie_id, :manifestation_dewey,
  :current_container, :in_container, :dewey_collocation, :barcode, :loan_status,
  :home_library_id, :issue_number, :item_icon, :custom_field1, :custom_field3,
  :rfid_code, :actual_library_id, :date_updated

  belongs_to :owner_library, class_name: 'ClavisLibrary', foreign_key: 'owner_library_id'
  belongs_to :home_library, class_name: 'ClavisLibrary', foreign_key: 'home_library_id'

  has_many :talking_books, :foreign_key=>'n', :primary_key=>'collocation'
  belongs_to :clavis_manifestation, :foreign_key=>:manifestation_id
  has_many :attachments, :as => :attachable
  has_one :open_shelf_item, foreign_key:'item_id'

  before_save :check_record
  after_save :piano_centrale

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

  def piano_centrale
    sql="SELECT collocazione,piano FROM clavis.centrale_locations WHERE item_id=#{self.id}"
    res=self.connection.execute(sql)
    return nil if res.ntuples==0
    piano=res.first['piano']
    if piano.nil?
      piano=SchemaCollocazioniCentrale.trova_piano(res.first['collocazione'])
      sql="UPDATE clavis.centrale_locations SET piano=#{self.connection.quote(piano)} WHERE item_id=#{self.id}"
      self.connection.execute(sql)
    end
    piano
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
    return "già presente in #{old_container.inspect}" if !old_container.nil?
    return "contenitore #{container.label} chiuso, elemento non aggiunto" if container.closed?

    if self.owner_library_id==-1
      c=ExtraCard.find(self.custom_field3)
      c.container_id=container.id
      c.save
      return "extracard: #{self.custom_field3} inserito in #{container.label}"
    else
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
  end

  def check_record
    if self.clavis_manifestation.nil?
      cm=ClavisManifestation.new({manifestation_id:self.manifestation_id,title:self.title})
      cm.save
    end
    if self.item_media.nil?
      # F = Monografia
      self.item_media='F'
    end
  end

  # Da rivedere bene
  def sanifica_collocazione
    if self.section!='BCT'
      self.sequence2='' if self.sequence2 =~ /prenot/
      self.sequence2='' if self.sequence2 =~ /Sala/
      self.collocation=self.collocation.split.first if !self.collocation.nil?
    end
  end

  def item_info
    sql=%Q{select c.*,os.*,l.label as nomebib from clavis.item ci left join container_items i on(i.item_id=ci.item_id) left join containers c on(c.id=i.container_id) left join clavis.library l on(l.library_id=c.library_id) left join open_shelf_items os on(os.item_id=ci.item_id) where ci.item_id = #{self.id}}
    r=ActiveRecord::Base.connection.execute(sql).first
    return nil if (r['label'].nil? and r['os_section'].nil?)
    r
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
    if mode==:ricolloca
      r="#{host}/index.php?page=Catalog.ItemInsertPage&bctricolloca=1&id=#{item_id}"
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

  def self.home_library
    sql=%Q{select library_id as key,label from clavis.library
      where library_status='A' AND library_internal='1' order by label}
    r=self.connection.execute(sql).collect {|i| [i['label'],i['key']]}
    r << ['Tutte',0]
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

  def ClavisItem.label_to_key(label,value_class)
    label.gsub!(/\(|\)$/, '')
    sql="select value_label,value_key from clavis.lookup_value where value_class = '#{value_class}' and value_language='it_IT' and value_label=#{self.connection.quote(label)}"
    res=self.connection.execute(sql).first
    res.nil? ? nil : res['value_key']
  end


  def ClavisItem.section_label_to_key(label,library_id)
    library_id=library_id.to_i
    label=self.connection.quote(label)
    sql=%Q{select value_key from clavis.library_value WHERE value_class='ITEMSECTION'
           and value_library_id=#{library_id} and value_label=#{label}}
    res=self.connection.execute(sql).first
    res.nil? ? nil : res['value_key']
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
    if params[:formula2]=='1'
      cond << "item.item_status!='F'"
    end

    cond << "cc.collocazione ~* #{ClavisItem.connection.quote(params[:collocation])}" if !params[:collocation].blank?

    cond = cond.join(' AND ')
    # order_by = params[:sort] == 'dewey' ? 'r.sort_text' : 'cm.edition_date desc, cc.sort_text'
    order_by = params[:sort] == 'dewey' ? 'r.sort_text' : 'cc.sort_text'

    ClavisItem.paginate(:conditions=>cond,:page=>params[:page], :per_page=>100,
                                        :select=>"os.item_id as open_shelf_item_id, item.item_id,
            item.inventory_serie_id || '-' || item.inventory_number as serieinv,
            item.inventory_serie_id,item.inventory_number,item.usage_count,item.item_status,
              item.title as title,cm.edition_date,cm.publisher,cm.manifestation_id,
            ist.value_label as item_status, lst.value_label as loan_status,
            item.opac_visible, cit.label as contenitore, r.vedetta, os.os_section,
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

  def ClavisItem.fifty_years(params)
    library_id = params[:owner_library_id].blank? ? 2 : params[:owner_library_id].to_i
    sql=%Q{SELECT ci.reprint,ci.barcode,ci.manifestation_id,ci.item_id,cm.edition_date,ci.volume_text, substr(ci.title, 1, 80) as title
 FROM clavis.item ci join clavis.manifestation cm using(manifestation_id)
 WHERE
  edition_date between 1500 and date_part('year', now())-50 and loan_class='B' and
     ci.owner_library_id=#{library_id}
   and ci.item_media='F' and not ci.volume_text ~* '(ristampa|rist).*[12][0-9]{3}'
  order by cm.edition_date, ci.item_id}
    ClavisItem.find_by_sql(sql)
  end

  def ClavisItem.controllo_valori_inventariali(params)
    if params[:year].blank?
      filter= ''
    else
      filter="inventory_date between '#{params[:year]}-01-1' and '#{params[:year]}-12-31' AND"
    end
    library_id = params[:owner_library_id].blank? ? 2 : params[:owner_library_id].to_i
    order = params[:order].blank? ? 'currency_value' : params[:order]
    sql=%Q{
select manifestation_id,title,item_id,inventory_date,created_by,inventory_value,currency_value,discount_value,
  round(currency_value-currency_value*(discount_value/100),2) as "Prezzo scontato"
 from clavis.item
  where
   #{filter}
    (inventory_value >0 or currency_value>0) and
   manifestation_id!=0 and item_source in ('C','E','F','O')
   and item_media in ('A','B','F','H','N','P','Q','R')
   -- and    (inventory_value>90 or currency_value>90)
   and inventory_value!=currency_value
 and round(currency_value-currency_value*(discount_value/100),2)!=inventory_value
 --   order by inventory_value desc
    order by #{order}
   limit 800}
    ClavisItem.find_by_sql(sql)
  end

  def ClavisItem.missing_numbers(scaffale, palchetto)
    return [] if scaffale.class!=Fixnum
    filtro = "^#{scaffale}\\.#{palchetto}\\."
    sql=%Q{SELECT collocazione FROM clavis.collocazioni c JOIN clavis.item i USING(item_id)
        WHERE i.home_library_id=2 AND collocazione ~ #{ClavisItem.connection.quote(filtro)}
        ORDER BY espandi_collocazione(collocazione);}
    res=ClavisItem.connection.execute(sql).to_a

    elenco=[]
    res.each do |r|
      catena = r['collocazione'].split('.')[2]

      next if catena.nil?
      numeri=catena.split('-')
      if numeri.size>1
        # puts "numeri: #{numeri} (#{numeri.size})  --- catena #{catena}"
        if numeri.size==2
          primo =numeri.first.to_i
          ultimo=numeri.last.to_i
          # puts "range: da #{primo} a #{ultimo}"
          while primo <= ultimo do
            elenco << primo
            primo += 1
          end
        else
          # tipo "216.F.4-5-6"
          numeri.each do |n|
            elenco << n.to_i
            catena = n.to_i
          end
        end
      else
        elenco << catena.to_i
      end
    end

    cnt=0
    res=[]
    elenco.each do |catena|
      # catena = r['collocazione'].split('.')[2].to_i
      # puts "Collocazione: #{r['collocazione']}"
      while cnt < catena-1 do
        cnt += 1
        res << cnt
      end
      # puts "catena: #{catena} ; lastnum: #{lastnum} - cnt=#{cnt}"
      cnt = catena
    end
    ClavisItem.compatta_lista_numeri(res)
  end

  def ClavisItem.compatta_lista_numeri(lista)
    prec=lista.shift
    res=[]
    inizio_range=fine_range=nil
    lista.each do |i|
      if (i - prec) == 1
        inizio_range=prec if inizio_range.nil?
        fine_range=i
        # puts "range da #{prec} a #{i}"
      else
        # puts "Salto di numero da #{prec} a #{i}"
        if !inizio_range.nil?
          # puts "sono preceduto da un range, da #{inizio_range} a #{fine_range}"
          if fine_range-inizio_range==1
            res << inizio_range
            res << fine_range
          else
            res << "#{inizio_range}-#{fine_range}"
          end
          inizio_range=fine_range=nil
        else
          res << prec
        end
      end
      prec=i
    end
    # puts "Uscito dal loop: #{prec} (#{inizio_range}-#{fine_range})"
    if inizio_range.nil?
      res << prec
    else
      if fine_range-inizio_range==1
        res << inizio_range
        res << fine_range
      else
        res << "#{inizio_range}-#{fine_range}"
      end
    end
    res.compact
  end

  def ClavisItem.piano(collocazione)
    puts "collocazione: #{collocazione}"
  end

  def ClavisItem.esemplari_disponibili(manifestation_ids, library_id)
    return manifestation_ids if manifestation_ids.class!=String
    sql=%Q{select item_id
      from clavis.manifestation cm join clavis.item ci using(manifestation_id)
       where cm.manifestation_id IN (#{manifestation_ids.strip.gsub(' ',',')})
       and ci.loan_class='B'
       and ci.owner_library_id=#{library_id}}
    # fd=File.open('/tmp/testami', 'w')
    # fd.write(sql)
    # fd.close
    ActiveRecord::Base.connection.execute(sql).to_a.collect {|x| x['item_id']}
  end

  def ClavisItem.lista_esemplari_con_tag_rfid(library_ids='')
    filter = library_ids.blank? ? '' : "AND cl.library_id IN (#{library_ids.split.join(',')})"
    sql=%Q{select cl.label as "biblioteca",cl.library_id, count(*) from clavis.item ci
  join clavis.library cl on(cl.library_id=ci.home_library_id) where rfid_code != '' #{filter}
    AND ci.item_status!='E' AND ci.barcode!=''
  group by cl.label,cl.library_id order by cl.label;}
    ActiveRecord::Base.connection.execute(sql)
  end

  def ClavisItem.conta_esemplari_senza_tag_rfid(library_id)
    sql=%Q{select count(*) from clavis.item where (rfid_code is null or rfid_code='')
      AND home_library_id=#{library_id} AND item_status='F' AND barcode!='' AND item_media='F'}
    ActiveRecord::Base.connection.execute(sql).to_a.first['count'].to_i
  end

end
