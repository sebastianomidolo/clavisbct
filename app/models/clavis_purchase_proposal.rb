# coding: utf-8
class ClavisPurchaseProposal < ActiveRecord::Base
  self.table_name='clavis.purchase_proposal'
  self.table_name='sbct_acquisti.proposte_acquisto'
  self.primary_key = 'proposal_id'

  attr_accessible :title, :patron_id, :status, :tipologia, :ean, :librarian_notes, :proposal_id, :modified_by
  attr_accessor :tipologia

  belongs_to :patron, :class_name=>'ClavisPatron'

  has_and_belongs_to_many(:sbct_titles, join_table:'sbct_acquisti.l_clavis_purchase_proposals_titles',
                          :foreign_key=>'proposal_id',
                          :association_foreign_key=>'id_titolo')


  def to_label
    "#{self.title} - #{self.ean} - #{self.author}"
  end

  def status_label
    sql=%Q{SELECT value_label FROM clavis.lookup_value WHERE value_class = 'PROPOSALSTATUS'
             AND value_language='it_IT' AND value_key='#{self.status}'}
    self.connection.execute(sql).first['value_label']
  end

  def patron_clavis_url
    ClavisPatron.clavis_url(self.patron_id)
  end

  def clavis_manifestation
    sql=%Q{select cm.manifestation_id FROM clavis.purchase_proposal pp, clavis.manifestation cm
             WHERE pp.proposal_id=#{self.id} AND (pp.ean = cm."ISBNISSN" or pp.ean=cm."EAN")
              AND length(pp.ean)>9}
    res=self.connection.execute(sql).first
    res.nil? ? nil : res['manifestation_id'].to_i
  end

  def insert_into_pac
    return SbctTitle.find(self.sbct_title_id) if !self.sbct_title_id.nil?
    cm_id = self.clavis_manifestation
    return nil if cm_id.nil?
    cm = ClavisManifestation.find(cm_id)
    t=SbctTitle.new(titolo:cm.title.strip,autore:cm.author.strip,manifestation_id:cm.id,ean:cm.EAN,isbn:cm.ISBNISSN,anno:cm.edition_date,note:"Inserimento automatico da proposta d'acquisto #{self.id}",editore:cm.publisher)
    t.save
  end

  # Necessaria, perché in questo modello table_name è una view
  def aggiorna_tabella(record)
    r=ClavisPurchaseProposal.new(record)
    sql = %Q{update clavis.purchase_proposal set ean=#{self.connection.quote(r.ean)},
             librarian_notes=#{self.connection.quote(r.librarian_notes)} where proposal_id=#{r.id}}
    self.connection.execute(sql)
    true
  end

  def sql_for_update_cpp
    self.item_status.strip!
    self.loan_class.strip!
    puts "item_status: \"#{self.item_status}\" -- loan_class: \"#{self.loan_class}\""
    return nil if self.manifestation_id.nil? or !['F','G','K'].include?(self.item_status) or !['B','C','F'].include?(self.loan_class)
    nota = %Q{Pubblicazione <a href="/opac/detail/view/sbct:catalog:#{self.manifestation_id.to_i}"> presente nel catalogo delle BCT</a>}
    sql=%Q{-- Da eseguire nello schema "clavis"
      -- ok item_status: #{self.item_status} -- loan_class: #{self.loan_class}
      update purchase_proposal set librarian_notes=#{self.connection.quote(nota)}
      where proposal_id=#{self.id};}
    # puts sql
    sql
  end

  # interval da esprimere in giorni, esempio '60 days'
  def ClavisPurchaseProposal.update_shelf(shelf_id, interval)
    shelf_id = shelf_id.to_i
    sq = %Q{select distinct manifestation_id
from sbct_acquisti.proposte_acquisto_details where inventory_date is not null and destbib is not null
and item_status IN ('F','G','K') and loan_class IN ('B','C','F')
and data_inserimento_pac < proposal_date
and status!='D' and age(now(),proposal_date) < interval '#{interval}'}
    sql = []
    sql << "DELETE FROM shelf_item WHERE shelf_id=#{shelf_id};"
    cnt = 0
    ClavisPurchaseProposal.find_by_sql(sq).each do |r|
      cnt += 1
      sql << "INSERT INTO shelf_item (shelf_id, object_id, object_class) VALUES(#{shelf_id}, #{r.manifestation_id}, 'manifestation');"
      # sql << "UPDATE turbomarc_cache set dirty='1' where manifestation_id=#{r.manifestation_id};"
    end
    sql2=sq.sub('60 days', '180 days')
    sql << "-- Segue aggiornamento turbomarc_cache non solo per i titoli inseriti ma anche per quelli che possono essere stati presenti nello scaffale nei precedenti 180 giorni (per pulire lo scaffale da residui precedentemente inseriti)"
    ClavisPurchaseProposal.find_by_sql(sql2).each do |r|
      sql << "UPDATE turbomarc_cache set dirty='1' where manifestation_id=#{r.manifestation_id};"
    end
    
    fname="/home/sites/456.selfip.net/html/clavis/shelf_update.sql"
    fname="/home/storage/backup_dati/shelf_update.sql"
    fd =File.open(fname, 'w')
    fd.write("-- Aggiornamento scaffale #{shelf_id} con #{cnt} proposte d'acquisto soddifatte negli ultimi #{interval}\n")
    fd.write("-- File sql generato da /clavis_purchase_proposals/sql_shelf_update - #{Time.now}\n")
    fd.write("-- sql utilizzato: #{sq.gsub("\n", "\n-- ")}\n")
    fd.write("BEGIN;\n")
    fd.write(sql.join("\n"))
    fd.write("\nCOMMIT;\n")
    fd.close
    File.read(fname)
  end

  def ClavisPurchaseProposal.update_cpp
    url_prefix="https://bct.comperio.it/opac/detail/view/sbct:catalog:"
    sq=%Q{select proposal_id, manifestation_id, status, stato_proposta,
array_to_string(array_agg(distinct item_status),',') as clavis_item_status,
array_to_string(array_agg(distinct trim(loan_class)),',') as clavis_loan_class,count(clavis_item_id)
from sbct_acquisti.proposte_acquisto_details
where manifestation_id is not null and status != 'D' and item_status in ('F','G','K')
    and loan_class in ('B','C','F')
    and (librarian_notes is null or not librarian_notes ~ '<a href=\"#{url_prefix}')
    and (librarian_notes is null or not librarian_notes ~ 'bct.medialibrary.it')
group by proposal_id, manifestation_id, status, stato_proposta}
    cpp = ClavisPurchaseProposal.find_by_sql(sq)
    sql = []
    cnt = 0
    cpp.each do |p|
      nota = %Q{<a href="#{url_prefix}#{p.manifestation_id.to_i}">Presente nel catalogo delle BCT</a>}
      sql << %Q{update purchase_proposal set modified_by=1, date_updated=now(), status='E',librarian_notes=#{self.connection.quote(nota)} where proposal_id=#{p.id} and status!='D';}
      cnt += 1
    end
    # sql << "SELECT proposal_id,librarian_notes from purchase_proposal where librarian_notes != '' and proposal_id in (#{ids.join(',')});"
    fname="/tmp/cpp_update.sql"
    fname="/home/storage/backup_dati/cpp_update.sql"
    fd =File.open(fname, 'w')
    fd.write("-- Aggiornamento di #{cnt} proposte d'acquisto\n")
    fd.write("-- File sql generato da /clavis_purchase_proposals/sql_cpp_update - #{Time.now}\n")
    fd.write("-- sql utilizzato: #{sq.gsub("\n", "\n-- ")}\n")
    fd.write("BEGIN;\n")
    fd.write(sql.join("\n"))
    fd.write("\nCOMMIT;\n")
    fd.close
    File.read(fname)
  end

  def ClavisPurchaseProposal.list(proposal,params)
    attrib=proposal.attributes.collect {|a| a if not a.last.blank?}.compact
    cond=[]
    proposals=[]
    attrib.each do |a|
      name,value=a
      case name
      when 'title'
        ts=self.connection.quote_string(value.split.join(' & '))
        cond << "to_tsvector('simple', proposte_acquisto.title) @@ to_tsquery('simple', '#{ts}')"
      when 'status'
        cond << "status = #{self.connection.quote(value)}"
      when 'patron_id'
        
      end
    end
    cond << "proposte_acquisto.patron_id=#{params[:patron_id]}" if params[:patron_id].to_i>0
    cond << "proposte_acquisto.notes ~ #{self.connection.quote(params[:tipologia])}" if !params[:tipologia].blank?

    select="purchase_proposal.*,lv.value_label as status_label,cm.manifestation_id"
    select="purchase_proposal.*"
    joins=%Q{JOIN clavis.lookup_value lv ON(lv.value_key=purchase_proposal.status AND value_class = 'PROPOSALSTATUS'
               AND value_language='it_IT')
             LEFT JOIN clavis.manifestation cm ON(cm."EAN"=purchase_proposal.ean AND cm."EAN" != '' AND purchase_proposal.ean!='')}

    joins=%Q{LEFT JOIN clavis.manifestation cm ON(cm."EAN"=purchase_proposal.ean AND cm."EAN" != '' AND purchase_proposal.ean!='')}
    joins = ''
    cond = cond.join(' AND ')
    if cond==''
      # cond = "purchase_proposal.date_created between now() - interval '15 days' and now()"
    end

    prm={
      conditions:cond,
      select:select,
      joins:joins,
      include:'patron',
      page:params[:page],
      per_page:100,
      :order=>'proposal_id desc'
    }

    ClavisPurchaseProposal.paginate(prm)
  end

  def ClavisPurchaseProposal.tutte(proposal,params)
    attrib=proposal.attributes.collect {|a| a if not a.last.blank?}.compact
    cond=[]
    attrib.each do |a|
      name,value=a
      case name
      when 'title'
        ts=self.connection.quote_string(value.split.join(' & '))
        cond << "to_tsvector('simple', pa.title) @@ to_tsquery('simple', '#{ts}')"
      when 'status'
        cond << "pa.status = #{self.connection.quote(value)}"
      when 'modified_by'
        cond << "pa.modified_by = #{value.to_i}"
      end
    end
    cond << "pa.patron_id=#{params[:patron_id]}" if params[:patron_id].to_i>0
    cond << "pa.notes ~ #{self.connection.quote(params[:tipologia])}" if !params[:tipologia].blank?
    if cond.size == 0
      cond = ''
    else
      cond = "WHERE #{cond.join(' AND ')}"
    end
    if proposal.status=='E'
      order = "order by pa.date_updated desc"
    else
      order = "order by pa.proposal_id desc"
    end

    # sql = %Q{SELECT * FROM sbct_acquisti.proposte_acquisto #{cond} #{order}}
    # sql = %Q{SELECT * FROM sbct_acquisti.proposte_acquisto #{cond} #{order}}
    sql = %Q{SELECT pa.*,cl.username FROM sbct_acquisti.proposte_acquisto pa
        join clavis.librarian cl on (cl.librarian_id=pa.modified_by) #{cond} #{order}}
    
    fd = File.open("/home/seb/proposte_acquisto.sql", "w")
    fd.write("#{sql}\n")
    fd.close
    ClavisPurchaseProposal.paginate_by_sql(sql, page:params[:page])
  end


  def ClavisPurchaseProposal.status_select
    sql=%Q{select value_key as key,value_label as label from clavis.lookup_value where (value_class = 'PROPOSALSTATUS' AND value_language='it_IT')}
    res = []
    self.connection.execute(sql).to_a.each do |r|
      label = "#{r['key']} - #{r['label']}"
      res << [label,r['key']]
    end
    res
  end
  def ClavisPurchaseProposal.tipologia_select
    [
      ['Libro', 'Libro'],
      ['eBook', 'eBook'],
      ['CD', 'CD'],
      ['DVD', 'DVD'],
      ['Rivista', 'Rivista'],
    ]
  end
  

end
