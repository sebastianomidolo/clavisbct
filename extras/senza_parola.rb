module SenzaParola

  def sp_sourcedir
    config = Rails.configuration.database_configuration
    config[Rails.env]["sp_source"]
  end

  def sp_primary_key(sourcedir)
    File.basename(sourcedir)
  end

  def sp_items_updated_after(timestamp)
    return [] if timestamp.nil?
    sourcedir = File.join(self.sourcedir, 'Deposito')
    puts "cerco files per #{self.id} - #{sourcedir}"
    res=[]
    Dir[(File.join(sourcedir,'*'))].collect do |f|
      if (File.stat(f).mtime > timestamp)
        # puts "'#{File.basename(f)}' mtime: #{File.stat(f).mtime} <=> #{timestamp}"
        res << File.basename(f)
      end
    end
    res
  end

  def sp_last_entries(max=nil)
    d=(Dir[(File.join(sp_sourcedir,'*'))].sort do |a,b|
         File.stat(a).mtime <=> File.stat(b).mtime
       end)
    max.nil? ? d.reverse : d.reverse[0..max-1]
  end

  def sp_new_bibliography(dirname_id)
    puts "In sp_new_bibliography: cerco o creo bib con dirname_id = #{dirname_id}"
    b = SpBibliography.find_by_orig_id(dirname_id)
    if b.nil?
      puts "creo nuova bibliografia con orig_id = #{dirname_id}"
      b = SpBibliography.new(orig_id:dirname_id)
      data=b.sp_read_bibliography_info
      b=SpBibliography.new(data)
      b.orig_id = dirname_id
      b.save
    end
    b
  end
  
  def tcl_load_file(fname)
    return nil if !File.exists?(fname)
    utfname="/tmp/tmp.utf8"
    cmd="/usr/bin/iconv -f latin1 -t utf8 #{fname} > #{utfname}"
    Kernel.system(cmd)
    Tcl::Interp.load_from_file(utfname)
  end

  def sp_read_bibliography_info
    sourcedir=self.sourcedir
    fh={
      'comm'  => :comment,
      'ctime' => :created_at,
      'mtime' => :updated_at,
      'name'  => :title,
      'subname' => :subtitle,
      'descr' => :description,
      'p_status' => :status
    }
    res={}
    i=tcl_load_file(File.join(self.sourcedir, 'info.tcl'))
    return res if i.nil?

    i.eval("array name ProInfo").split.each do |vn|
      v=i.var("ProInfo(#{vn})").value
      next if v.blank? or ['nsked','nascondi'].include?(vn)
      k = fh[vn].nil? ? vn.to_sym : fh[vn]
      if ['ctime','mtime'].include?(vn)
        # res[k] = Time.parse(i.eval(%Q{clock format #{v} -format "%Y-%m-%d %H:%M:%S"}))
        res[k] = i.eval(%Q{clock format #{v} -format "%Y-%m-%d %H:%M:%S"})
      else
        res[k] = v.strip
      end
    end
    res
  end

  def sp_read_section_info
    fh={
      'key' => :sortkey,
      'tit' => :title,
      'did' => :description,
    }
    res={}
    fname=File.join(self.sourcedir, 'sect.tcl')
    return nil if !File.exists?(fname)
    i=tcl_load_file(fname)
    # Ogni sezione ha questi campi:
    fields="parent key tit did status exp"
    sections=[]
    i.eval("array name SectInfo").split.each do |sn|
      v=i.var("SectInfo(#{sn})").value
      i.eval("foreach {#{fields}} [list #{v}] {}")
      hs={}
      hs[:number]=sn
      fields.split.each do |f|
        k = fh[f].nil? ? f.to_sym : fh[f]
        hs[k] = i.var(f).value if !i.var(f).value.blank?
      end
      sections << hs
    end
    return nil if sections.size==0
    res[:sections]=sections
    res
  end

  def sp_sked_fname(item_id)
    File.join(self.sourcedir, "Deposito", item_id)
  end

  def sp_read_item_info(item_id)
    # puts "determino fname per item_id #{item_id} di bibl #{self.id}"
    fname = self.sp_sked_fname(item_id)
    return nil if !File.exists?(fname)
    fh={
      'descr' => :bibdescr,
      'ctime' => :created_at,
      'mtime' => :updated_at,
      'section' => :section_number,
      'urlref_2' => :sbn_bid,
      'key'   => :sortkey,
    }
    res={}
    res[:item_id]=item_id
    # puts "RES QUI: #{res.inspect}"
    i=tcl_load_file(fname)
    fields = i.eval("array name SkInfo")
    fields.split.each do |f|
      v=i.var("SkInfo(#{f})").value.strip
      next if v.blank? or ['urlref_1','urlref_3','urlref_4','impronta'].include?(f)
      k = fh[f].nil? ? f.to_sym : fh[f]
      if ['ctime','mtime'].include?(f)
        # ih[k] = Time.parse(i.eval(%Q{clock format #{v} -format "%Y-%m-%d %H:%M:%S"}))
        res[k] = i.eval(%Q{clock format #{v} -format "%Y-%m-%d %H:%M:%S"})
      else
        res[k] = v
      end
    end
    res
  end

  def sp_latex_to_html(src)
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
    fdout.write(src)
    fdout.close

    cmd = "/usr/bin/latex2html -lcase_tags #{tempfile} > /dev/null 2>/dev/null"
    # puts cmd
    Kernel.system(cmd)
    data=File.read(File.join(outdir, 'index.html'))
    i=data.index("<!--End of Navigation Panel-->")+30
    x=data.index("<!--Table of Child-Links-->")-1
    data=data[i..x]
    data.strip!
    data.gsub!('<p>','<br/>')
    data.gsub!('<br>','<br/>')
    data.gsub!('<hr>','')
    data.gsub!('``','"')
    data.gsub!(/^<br\/>/, '')
    # Ripetizione necessaria, non eliminare:
    data.strip!
    data
  end

end
