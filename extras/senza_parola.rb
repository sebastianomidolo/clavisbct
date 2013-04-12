module SenzaParola

  def tcl_load_file(fname)
    utfname="/tmp/tmp.utf8"
    cmd="/usr/bin/iconv -f latin1 -t utf8 #{fname} > #{utfname}"
    Kernel.system(cmd)
    Tcl::Interp.load_from_file(utfname)
  end


  def read_bibliography_info(sourcedir)
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
    res[:id]=File.basename(sourcedir)

    i=tcl_load_file(File.join(sourcedir, 'info.tcl'))
    
    # puts File.join(sourcedir, 'info.tcl')
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
    data.gsub!('<p>','<br/>')
    data.gsub!('<br>','<br/>')
    data.gsub!('<hr>','')
    data.gsub!('``','"')
    data
  end

end
