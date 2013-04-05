# -*- mode: ruby;-*-

# Esempio. In development:
# RAILS_ENV=development rake senza_parola
# In production:
# RAILS_ENV=production  rake senza_parola

desc 'Importazione bibliografie da SenzaParola'

task :senza_parola => :environment do

  def tcl_load_file(fname)
    # return Tcl::Interp.load_from_file(fname)
    # x = Kernel.system("/usr/bin/file #{fname}")
    # puts "x: #{x}"
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

  def import_sp_bibliographies(rootdir, dbname, username)
    # Primo livello: elenco delle bibliografie - destinazione => sp_bibliographies
    attrib=[
            :id,
            :created_at,
            :description,
            :html_description,
            :status,
            :subtitle,
            :title,
            :updated_at,
           ]
    tempdir = File.join(Rails.root.to_s, 'tmp')
    tf = Tempfile.new("import",tempdir)
    tempfile=tf.path
    fdout=File.open(tempfile,'w')
    fdout.write("TRUNCATE sp.sp_bibliographies CASCADE;\n")
    fdout.write("COPY sp.sp_bibliographies (#{attrib.join(',')}) FROM stdin;\n")
    enc=HTMLEntities.new
    Dir.glob(File.join(rootdir, '*')).each do |d|
      puts d
      info = read_bibliography_info(d)
      data=[]
      if !info[:description].blank?
        v = info[:description].force_encoding('utf-8').encode('utf-8')
        v.gsub!("\n", '\r')
        v.gsub!("\t", "TABULATORE")
        v.gsub!("\\", 'B_A_C_K_S_L_A_S_H')
        info[:html_description] = SpBibliography.latex_html(v)
      end
      attrib.each do |a|
        v = info[a]
        if v.blank?
          v = "\\N"
        else
          if a==:html_description
            v.gsub!("\n", '')
            v.gsub!("\t", "TABULATORE")
          else
            v = v.force_encoding('utf-8').encode('utf-8')
            v = enc.decode(v)
            v.gsub!("\n", '\r')
            v.gsub!("\t", "TABULATORE")
            # v.gsub!("\\", 'B_A_C_K_S_L_A_S_H')
          end
        end
        data << v
      end
      fdout.write(%Q{#{data.join("\t")}\n})
    end
    fdout.write("\\.\n")
    fdout.close
    cmd="/bin/cp #{tempfile} /tmp/1_senzaparola_import_bibliografie.sql"
    puts cmd
    Kernel.system(cmd)
    cmd="/usr/bin/psql --no-psqlrc --quiet -d #{dbname} #{username}  -f #{tempfile}"
    # puts cmd
    Kernel.system(cmd)
    tf.close(true)
  end

  def read_sections_info(sourcedir)
    fh={
      'key' => :sortkey,
      'tit' => :title,
      'did' => :description,
    }
    res={}
    fname=File.join(sourcedir, 'sect.tcl')
    return nil if !File.exists?(fname)
    res[:bibliography_id]=File.basename(sourcedir)
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

  def import_sp_sections(rootdir, dbname, username)
    # Secondo livello: elenco delle sezioni - destinazione => sp_sections
    attrib=[
            :bibliography_id,
            :number,
            :parent,
            :title,
            :description,
            :sortkey,
            :status,
           ]
    tf = Tempfile.new("import", File.join(Rails.root.to_s, 'tmp'))
    tempfile=tf.path
    fdout=File.open(tempfile,'w')
    fdout.write("TRUNCATE sp.sp_sections CASCADE;\n")
    fdout.write("COPY sp.sp_sections (#{attrib.join(',')}) FROM stdin;\n")
    enc=HTMLEntities.new
    Dir.glob(File.join(rootdir, '*')).each do |d|
      infosection = read_sections_info(d)
      next if infosection.nil?
      infosection[:sections].each do |i|
        data=[]
        i[:bibliography_id] = infosection[:bibliography_id]
        attrib.each do |a|
          v = i[a]
          if v.blank?
            v = "\\N"
          else
            v = v.force_encoding('utf-8').encode('utf-8')
            v = enc.decode(v)
            v.gsub!("\n", '\r')
            v.gsub!("\t", "TABULATORE")
          end
          data << v
        end
        fdout.write(%Q{#{data.join("\t")}\n})

      end
    end
    fdout.write("\\.\n")
    fdout.close
    cmd="/bin/cp #{tempfile} /tmp/2_sections_provvisorio_da_cancellare.sql"
    puts cmd
    Kernel.system(cmd)
    cmd="/usr/bin/psql --no-psqlrc --quiet -d #{dbname} #{username}  -f #{tempfile}"
    puts cmd
    Kernel.system(cmd)
    tf.close(true)
  end

  def read_items_info(sourcedir)
    fh={
      'descr' => :bibdescr,
      'ctime' => :created_at,
      'mtime' => :updated_at,
      'section' => :section_number,
      'urlref_2' => :sbn_bid,
      'key'   => :sortkey,
    }
    res={}
    res[:bibliography_id]=File.basename(sourcedir)
    items=[]
    Dir.glob(File.join(sourcedir, 'Deposito', '*')).each do |sk|
      # puts sk
      sk_id=File.basename(sk)
      # next if sk_id!="TI49hJ5mOMsAAAQ4Q-0"
      i=tcl_load_file(sk)

      fields = i.eval("array name SkInfo")
      ih={}
      fields.split.each do |f|
        v=i.var("SkInfo(#{f})").value.strip
        next if v.blank? or ['urlref_1','urlref_3','urlref_4','impronta'].include?(f)
        k = fh[f].nil? ? f.to_sym : fh[f]
        if ['ctime','mtime'].include?(f)
          # ih[k] = Time.parse(i.eval(%Q{clock format #{v} -format "%Y-%m-%d %H:%M:%S"}))
          ih[k] = i.eval(%Q{clock format #{v} -format "%Y-%m-%d %H:%M:%S"})
        else
          # v.gsub!("\n", '\r')
          # v.gsub!("\\", 'BACKSLASH')
          # v.gsub!("\t", "TABULATORE")
          ih[k] = v
        end
      end
      ih[:item_id]=sk_id
      items << ih
    end
    res[:items] = items
    res
  end

  def import_sp_items(rootdir, dbname, username)
    # Terzo livello: items (i titoli in bibliografia) - destinazione => sp_items
    attrib=[:item_id,
            :bibliography_id,
            :created_at,
            :updated_at,
            :bibdescr,
            :collciv,
            :colldec,
            :mainentry,
            :note,
            :sbn_bid,
            :section_number,
            :sigle,
            :sortkey,
           ]
    
    tf = Tempfile.new("import", File.join(Rails.root.to_s, 'tmp'))
    tempfile=tf.path
    fdout=File.open(tempfile,'w')
    fdout.write("TRUNCATE sp.sp_items;\n")
    fdout.write("SELECT setval('sp.sp_items_id_seq', 1);\n")
    fdout.write("COPY sp.sp_items (#{attrib.join(',')}) FROM stdin;\n")

    enc=HTMLEntities.new
    Dir.glob(File.join(rootdir, '*')).each do |d|
      items = read_items_info(d)

      items[:items].each do |i|
        i[:bibliography_id]=items[:bibliography_id]
        data=[]
        attrib.each do |a|
          v = i[a]
          if v.blank?
            v = "\\N"
          else
            v = v.force_encoding('utf-8').encode('utf-8')
            v = enc.decode(v)
            v.gsub!("\n", '\r')
            v.gsub!("\r", '\r')
            v.gsub!("\\", 'B_A_C_K_S_L_A_S_H')
            v.gsub!("\t", "TABULATORE")
          end
          data << v
        end
        fdout.write(%Q{#{data.join("\t")}\n})
        fdout.flush
      end
    end
    fdout.write("\\.\n")
    fdout.close
    cmd="/bin/cp #{tempfile} /tmp/3_items_provvisorio_da_cancellare.sql"
    puts cmd
    Kernel.system(cmd)
    cmd="/usr/bin/psql --no-psqlrc --quiet -d #{dbname} #{username}  -f #{tempfile}"
    puts cmd
    Kernel.system(cmd)
    tf.close(true)
  end

  config = Rails.configuration.database_configuration
  dbname=config[Rails.env]["database"]
  username=config[Rails.env]["username"]
  source=config[Rails.env]["sp_source"]
  rootdir=File.join(source, 'Projects')
  import_sp_bibliographies(rootdir, dbname, username)
  import_sp_sections(rootdir, dbname, username)
  import_sp_items(rootdir, dbname, username)

  sql=%Q{
   UPDATE sp.sp_bibliographies set title=replace(title,'``','"') where title ~* '``';
   UPDATE sp.sp_items set bibdescr=replace(bibdescr,'B_A_C_K_S_L_A_S_Hr','<br/>')
     WHERE bibdescr ~* 'B_A_C_K_S_L_A_S_Hr';
   UPDATE sp.sp_items set bibdescr=replace(bibdescr,'B_A_C_K_S_L_A_S_Hpar','<br/>')
     WHERE bibdescr ~* 'B_A_C_K_S_L_A_S_Hpar';
  }
  SpItem.connection.execute(sql)
  puts "importazione completata"
end

