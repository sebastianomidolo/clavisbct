# coding: utf-8
include SenzaParola

class SpBibliography < ActiveRecord::Base
  self.table_name='sp.sp_bibliographies'
  attr_accessible :comment, :description, :status, :subtitle, :title, :html_description, :orig_id, :library_id, :updated_by, :homepage

  has_many :sp_items, :foreign_key=>'bibliography_id'
  
  has_and_belongs_to_many :users, :join_table=>'sp.sp_users', foreign_key:'bibliography_id'

  belongs_to :clavis_library, foreign_key:'library_id'

  def sp_items_toplevel
    SpItem.where(bibliography_id:self.id,section_number:nil).order('sortkey')
  end

  def to_label
    r=String.new(self.title)
    r << ". #{self.subtitle}" if !self.subtitle.blank?
    r
  end

  def description_html
    self.html_description
    #return '' if self.description.nil?
    #SpBibliography.latex_html(self.description)
  end

  def sourcedir
    return nil if self.orig_id.nil?
    File.join(SenzaParola::sp_sourcedir, self.respond_to?(:orig_id) ? self.orig_id.strip : self.id)
  end

  def cover_image
    return nil if self.sourcedir.nil?
    f=File.join(self.sourcedir, 'Img', 'formato_latex-img_pp.jpg')
    File.exists?(f) ? f : nil
  end

  def senza_parola_bibliography_path
    "http://biblio.comune.torino.it:8080/ProgettiCivica/SenzaParola/typo.cgi?id=#{self.id}&rm=list"
  end

  def sync_sections
    puts "Carico le sezioni della bib #{self.id} \"#{self.title}\" (id originale: #{self.orig_id.strip})"
    sections=self.sp_read_section_info
    if sections.nil?
      SpBibliography.connection.execute("DELETE FROM sp.sp_sections WHERE bibliography_id='#{self.id}'")
      return
    end
    hs={}
    sections[:sections].each do |i|
      num=i[:number].to_i
      hs[num]=i
    end
    puts "numero sezioni definite su fs: #{hs.size}"
    puts "numero sezioni presenti su db: #{self.all_sp_sections.size}"
    
    enc=HTMLEntities.new
    self.all_sp_sections.each do |sec|
      # puts "sec.number: #{sec.number} \"#{sec.title}\""
      if hs[sec.number].nil?
        puts "sezione #{sec.number} da cancellare: #{sec.title}"
        SpBibliography.connection.execute("DELETE FROM sp.sp_sections WHERE bibliography_id='#{self.id}' AND number=#{sec.number}")
      else
        puts "sezione #{sec.number} eventualmente da modificare: #{sec.title}"
        info=hs[sec.number]
        sql=[]
        cng=0
        sec.attributes.keys.each do |k|
          k=k.to_sym; next if [:number, :bibliography_id].include?(k)
          if info[k].blank?
            val =  nil
            if !sec[k].nil?
              sql << "#{k}=NULL"
            end
          else
            val =  info[k].force_encoding('utf-8').encode('utf-8')
            val.gsub!("``", '"')
            if val!=sec[k].to_s
              # puts "val: #{sec[k]}"
              sql << "#{k}=#{SpSection.connection.quote(val)}"
            end
          end
        end
        if sql.size>0
          SpItem.connection.execute("UPDATE sp.sp_sections SET #{sql.join(',')} WHERE bibliography_id='#{self.id}' AND number=#{sec.number}")
        end
      end
      hs.delete(sec.number)
    end
    # Infine aggiungo eventuali nuove sezioni
    hs.each_pair do |k,i|
      puts "aggiungo sezione #{i[:number]} \"#{i[:title]}\""
      i[:bibliography_id]=self.id
      s=SpSection.new(i)
      s.title.gsub!("``", '"')
      puts s.inspect
      s.save
    end
  end

  def sync_items
    enc=HTMLEntities.new
    # Cancellazione items non presenti sul file system
    sourcedir=File.join(self.sourcedir, 'Deposito')
    self.sp_items.each do |sk|
      fname=File.join(sourcedir, sk.item_id)
      if !File.exists?(File.join(sourcedir, sk.item_id))
        puts "record da cancellare: #{sk.item_id} => #{sk.id}"
        sk.delete
      end
    end
    SpItem.connection.execute("update sp.sp_items set updated_at = created_at where bibliography_id=#{SpItem.connection.quote(self.id)} AND updated_at isnull;")
    puts "items per bibliografia #{self.id}"
    last_item=SpItem.find_all_by_bibliography_id(self.id, :order=>'updated_at asc', :limit=>1).first
    if last_item.nil?
      puts "nessun titolo"
    else
      puts "last_item: #{last_item.id}"
    end
    timestamp = last_item.nil? ? nil : last_item.updated_at
    puts "ok timestamp #{timestamp}"
    self.sp_items_updated_after(timestamp).each do |item_id|
      # puts "leggo item con item_id #{item_id} e bibliography_id=#{self.id}"
      iteminfo=sp_read_item_info(item_id)
      sp_item=SpItem.find_by_bibliography_id_and_item_id(self.id,item_id)
      if sp_item.nil?
        puts "nuovo sp_item per #{self.id} => #{item_id}"
        next
      else
        # puts "aggiorno sp_item.id: #{sp_item.id} #{sp_item.item_id}"
        sp_item.attributes.keys.each do |k|
          k=k.to_sym; next if [:id, :item_id, :bibliography_id].include?(k)
          sp_item[k]=nil
        end
        sp_item.attributes.keys.each do |k|
          k=k.to_sym; next if [:id, :item_id, :bibliography_id].include?(k)
          if k==:updated_at
            # puts "Attenzione: updated_at: #{iteminfo[k]}"
          end
          if k==:updated_at or iteminfo[k].blank?
            sp_item[k] = iteminfo[k]
          else
            val = iteminfo[k].force_encoding('utf-8').encode('utf-8')
            sp_item[k]=enc.decode(val)
          end

        end
      end
      if sp_item.changed?
        sp_item.save!
        puts "sp_item #{sp_item.id} changed"
      end
      # puts "sp_item: #{sp_item.inspect}"
    end

    item_ids=self.sp_items.collect {|s| s.item_id}
    puts "infine carico eventuali nuove schede da #{sourcedir}"
    new_items=Dir[(File.join(sourcedir,'*'))].collect {|f| File.basename(f)}
    new_items.each do |item_id|
      if item_ids.include?(item_id)
        # puts "item_id #{item_id} gia' presente, salto"
        next
      end
      iteminfo=sp_read_item_info(item_id)
      iteminfo.keys.each do |k|
        next if iteminfo[k].blank?
        iteminfo[k]=enc.decode(iteminfo[k].force_encoding('utf-8').encode('utf-8'))
      end
      iteminfo[:bibliography_id]=self.id
      sp_item=SpItem.new(iteminfo)
      if sp_item.bibdescr.blank?
        puts "Errore: scheda #{sp_item.item_id} della bibliografia #{sp_item.bibliography_id} priva di descrizione bibliografica"
        next
      end
      sp_item.sortkey = sp_item.bibdescr if sp_item.sortkey.blank?
      sp_item.sortkey=sp_item.sortkey[0..511]
      if sp_item.created_at.nil?
        fname=File.join(sourcedir, item_id)
        # puts "non ho la data nel record, la leggo dal file: #{fname}"
        sp_item.created_at=File.stat(fname).mtime
        sp_item.updated_at=sp_item.created_at
      end
      sp_item.save
    end

  end

  def updated_at_set
    sql=%Q{UPDATE sp.sp_bibliographies SET updated_at=(SELECT max(updated_at)
  FROM sp.sp_items
  WHERE bibliography_id=#{self.id}) where id=#{self.id};}
    # puts sql
    SpBibliography.connection.execute(sql)
  end

  def syncronize_with_filesystem
    # puts self.id
    info=self.sp_read_bibliography_info
    self.attributes.keys.each do |k|
      k=k.to_sym
      next if info[k].nil?
      val = info[k].force_encoding('utf-8').encode('utf-8')
      # puts "k: #{k} #{k.class} (#{info[k]})"
      if self[k]==val or k==:updated_at
        # puts "#{k} non cambiato"
      else
        puts "#{k} MODIFICATO"
        self[k]=info[k]
      end
    end
    if !self.description.blank?
      # t=self.description.force_encoding('utf-8').encode('utf-8')
      t=self.description
      self.html_description=SenzaParola::sp_latex_to_html(t)
    end
    self.save if self.changed?
  end

  def SpBibliography.sanifica_html(html)
    return html if /</ =~ '<'
    return nil if html.nil?
    s=Nokogiri::HTML::DocumentFragment.parse(html)
    s=s.to_html
    s.gsub!(/<br>/, '<br/>')
    #s.gsub!(/^(<br>)+|(<br>)+$/,'')
    s.gsub!(/^<br\/>|<br\/>$/,'')
    s
  end

  def SpBibliography.latex2html(inputdata)
    return (inputdata.nil? ? 'no_data' : inputdata)
    tempdir = File.join(Rails.root.to_s, 'tmp')
    tf = Tempfile.new("sp_item",tempdir)
    infile=tf.path
    fd = File.open(infile, 'w')
    fd.write(inputdata)
    fd.close
    outfile="#{tf.path}.out"
    cmd = "/usr/local/bin/pandoc -f latex -t html #{infile} -o #{outfile}"
    data = ''
    if Kernel.system(cmd)
      fd = File.open(outfile)
      data = fd.read
      fd.close
    end
    tf.close(true)
    data
  end

  def SpBibliography.latex_html(src)
    # tf = Tempfile.new("import", File.join(Rails.root.to_s, 'tmp'))
    #tempdir=tf.path
    #tempfile=tf.path + ".tex"


    basename = "xyz"
    workdir  = "/tmp"
    outdir   = File.join(workdir, basename)
    # puts "outdir: #{outdir}"
    tempfile = File.join(workdir, "#{basename}.tex")
    # puts tempfile

    # tempfile="/tmp/templatex.tex"
    fdout=File.open(tempfile,'w')

    # src.gsub!("", "\\b")
    #src.gsub!("begin", "\n\\begin")
    #src.gsub!("item", "\n\\item")
    #src.gsub!("end", "\n\\end")
    # src.gsub!("", "\n")
    src.gsub!("B_A_C_K_S_L_A_S_Hrm", "\\\\rm")
    src.gsub!("B_A_C_K_S_L_A_S_Hr", "\n")
    src.gsub!("B_A_C_K_S_L_A_S_H", '\\\\')
    src.gsub!("%", '\\%')
    fdout.write(src)
    fdout.close

    cmd = "/usr/bin/latex2html -lcase_tags #{tempfile} > /dev/null 2>/dev/null"
    # puts cmd
    Kernel.system(cmd)
    data=File.read(File.join(outdir, 'index.html'))
    i=data.index("<!--End of Navigation Panel-->")+30
    x=data.index("<!--Table of Child-Links-->")-1
    data=data[i..x]
    data.gsub!('<p>','<br/>')
    data.gsub!('<br>','<br/>')
    data.gsub!('<hr>','')
    data.gsub!('``','"')
    data
  end


  def SpBibliography.delete_empty_bibliographies
    sql=%Q{DELETE FROM sp.sp_bibliographies WHERE id IN
   (SELECT b.id FROM sp.sp_bibliographies b LEFT JOIN sp.sp_items i
     ON(b.id=i.bibliography_id) where i ISNULL)}
    SpBibliography.connection.execute(sql)
  end

  def SpBibliography.sync_all(max=nil)
    SpBibliography.connection.execute("SELECT setval('sp.sp_items_id_seq', (select max(id)+1 from sp.sp_items))")
    cnt=0
    SenzaParola::sp_last_entries(max).each do |d|
      cnt+=1
      dirname_id=SenzaParola::sp_primary_key(d)
      puts "==> ##{cnt} dirname_id: '#{dirname_id}'"
      b=SpBibliography.find_by_orig_id(dirname_id)
      if !b.nil?
        puts "aggiorno bibliografia #{b.id} =>#{b.title}"
      else
        puts "nuova bibliografia: #{dirname_id}"
        begin
          b=SenzaParola::sp_new_bibliography(dirname_id)
        rescue
          b=nil
          puts "Errore da SenzaParola::sp_new_bibliography(#{dirname_id})"
          return
        end
        puts "Creata nuova bibliografia #{b.id} a partire da #{d}"
      end
      if !b.nil?
        b.syncronize_with_filesystem
        b.sync_sections
        b.sync_items
        b.updated_at_set
        # self.delete_empty_bibliographies
      end
    end
  end

  def next_section_number
    r=self.connection.execute("select max(number) from sp.sp_sections where bibliography_id=#{self.id}").to_a.first['max']
    r.nil? ? 1 : r.to_i+1
  end

  def sp_sections(logged_in=true)
    # puts "logged_in: #{logged_in}"
    cond = logged_in ? '' : "and status='1'"
    sql=%Q{SELECT * FROM sp.sp_sections WHERE bibliography_id = '#{self.id}' and parent=0 #{cond} order by sortkey,title}
    SpSection.find_by_sql(sql)
  end

  def all_sp_sections
    sql=%Q{SELECT * FROM sp.sp_sections WHERE bibliography_id = '#{self.id}'}
    SpSection.find_by_sql(sql)
  end
  
  def section_select(sections=nil,level=0,res=[])
    if sections.nil?
      sections = self.sp_sections
      res=[]
    end
    sections.each do |s|
      level = 1 if s.parent == 0
      tabs = " - " * (level-1)
      label = "#{tabs}#{s.title}"
      res << [label,s.number]
      self.section_select(s.sp_sections,level+1,res) if s.sp_sections!=[]
    end
    res
  end

  def status_label
    SpBibliography.status_select.each do |s|
      return s[0] if s[1]==self.status
    end
    nil
  end

  def published?
    self.status=='N' ? false : true
  end

  def library_id_label
    self.library_id.nil? ? 'Sistema BCT' : self.clavis_library.to_label
  end

  def SpBibliography.status_select
    [
      ['Non pubblicata', 'N'],
      ['Pubblicata (in lavorazione)', 'C'],
      ['Pubblicata (archiviata)', 'A'],
    ]
  end
end
