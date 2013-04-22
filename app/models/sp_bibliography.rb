include SenzaParola

class SpBibliography < ActiveRecord::Base
  self.table_name='sp.sp_bibliographies'
  SpBibliography.record_timestamps = false
  attr_accessible :comment, :created_at, :description, :status, :subtitle, :title, :updated_at

  has_many :sp_sections, :foreign_key=>'bibliography_id'
  has_many(:toplevel_sections, :class_name=>'SpSection',
           :foreign_key=>'bibliography_id', :conditions=>'parent=0',
           :order=>'sortkey')

  has_many :sp_items, :foreign_key=>'bibliography_id'
  
  def description_html
    self.html_description
    #return '' if self.description.nil?
    #SpBibliography.latex_html(self.description)
  end

  def sourcedir
    File.join(SenzaParola::sp_sourcedir, self.id)
  end

  def sync_sections
    sections=SenzaParola::sp_read_section_info(self.id)
    if sections.nil?
      SpBibliography.connection.execute("DELETE FROM sp.sp_sections WHERE bibliography_id='#{self.id}'")
      return
    end
    hs={}
    sections[:sections].each do |i|
      num=i[:number].to_i
      hs[num]=i
    end
    enc=HTMLEntities.new
    self.sp_sections.each do |sec|
      # puts "sec.number: #{sec.number}"
      if hs[sec.number].nil?
        # puts "sezione da cancellare: #{sec.inspect}"
        SpBibliography.connection.execute("DELETE FROM sp.sp_sections WHERE bibliography_id='#{self.id}' AND number=#{sec.number}")
      else
        # puts "sezione eventualmente da modificare: #{sec.inspect}"
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
      puts "aggiungo #{i.inspect}"
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
    sourcedir=File.join(SenzaParola::sp_sourcedir, self.id, 'Deposito')
    self.sp_items.each do |sk|
      fname=File.join(sourcedir, sk.item_id)
      if !File.exists?(File.join(sourcedir, sk.item_id))
        puts "record da cancellare: #{sk.item_id} => #{sk.id}"
        sk.delete
      end
    end
    SpItem.connection.execute("update sp.sp_items set updated_at = created_at where bibliography_id=#{SpItem.connection.quote(self.id)} AND updated_at isnull;")
    puts "items per bibliografia #{self.id}"
    last_item=SpItem.find_all_by_bibliography_id(self.id, :order=>'updated_at desc', :limit=>1).first
    if last_item.nil?
      # puts "nessun titolo"
    else
      # puts "last_item: #{last_item.id}"
    end
    timestamp = last_item.nil? ? nil : last_item.updated_at
    # puts timestamp
    SenzaParola::sp_items_updated_after(self.id, timestamp).each do |item_id|
      # puts "leggo item con item_id #{item_id} e bibliography_id=#{self.id}"
      iteminfo=sp_read_item_info(self.id, item_id)
      sp_item=SpItem.find_by_bibliography_id_and_item_id(self.id,item_id)
      if sp_item.nil?
        # puts "nuovo sp_item per #{self.id} => #{item_id}"
        next
      else
        # puts "aggiorno sp_item.id: #{sp_item.id} #{sp_item.item_id}"
        sp_item.attributes.keys.each do |k|
          k=k.to_sym; next if [:id, :item_id, :bibliography_id].include?(k)
          sp_item[k]=nil
        end
        sp_item.attributes.keys.each do |k|
          k=k.to_sym; next if [:id, :item_id, :bibliography_id].include?(k)
          next if k==:updated_at or iteminfo[k].blank?

          val = iteminfo[k].force_encoding('utf-8').encode('utf-8')
          sp_item[k]=enc.decode(val)

        end
      end
      sp_item.updated_at=Time.now
      sp_item.save!
      # puts "sp_item: #{sp_item.inspect}"
    end
    item_ids=self.sp_items.collect {|s| s.item_id}
    # puts "infine carico eventuali nuove schede da #{sourcedir}"
    new_items=Dir[(File.join(sourcedir,'*'))].collect {|f| File.basename(f)}
    new_items.each do |item_id|
      if item_ids.include?(item_id)
        # puts "item_id #{item_id} gia' presente, salto"
        next
      end
      iteminfo=sp_read_item_info(self.id, item_id)
      iteminfo.keys.each do |k|
        next if iteminfo[k].blank?
        iteminfo[k]=enc.decode(iteminfo[k].force_encoding('utf-8').encode('utf-8'))
      end
      sp_item=SpItem.new(iteminfo)
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
  WHERE bibliography_id='#{self.id}') where id='#{self.id}';}
    # puts sql
    SpBibliography.connection.execute(sql)
  end

  def syncronize_with_filesystem
    # puts self.id
    info=SenzaParola::sp_read_bibliography_info(self.sourcedir)
    self.attributes.keys.each do |k|
      k=k.to_sym
      next if info[k].nil?
      val = info[k].force_encoding('utf-8').encode('utf-8')
      # puts "k: #{k} #{k.class} (#{info[k]})"
      if self[k]==val or k==:updated_at
        # puts "#{k} non cambiato"
      else
        puts "#{k} CAMBIA da '#{self[k]}' a '#{info[k]}'"
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
      id=SenzaParola::sp_primary_key(d)
      puts "==> ##{cnt} id '#{id}'"
      if SpBibliography.exists?(id)
        b=SpBibliography.find(id)
        puts "aggiorno bibliografia #{id} =>#{b.title}"
      else
        puts "nuova bibliografia: #{id}"
        b=SenzaParola::sp_new_bibliography(id)
      end
      if !b.nil?
        # puts "b.class: #{b.class}"
        b.syncronize_with_filesystem
        b.sync_sections
        b.sync_items
        b.updated_at_set
        self.delete_empty_bibliographies
      end
    end
  end

end
