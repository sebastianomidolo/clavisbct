# coding: utf-8
require 'filemagic'

FILENAME_METADATA_TAGS=[:au,:ti,:an,:mid,:pp,:uid,:sc,:dc]

module DigitalObjects
  def digital_objects_mount_point
    config = Rails.configuration.database_configuration
    config[Rails.env]["digital_objects_mount_point"]
  end

  def digital_objects_cache
    config = Rails.configuration.database_configuration
    config[Rails.env]["digital_objects_cache"]
  end

  def digital_objects_audioclips_dir
    config = Rails.configuration.database_configuration
    config[Rails.env]["digital_objects_audioclips_dir"]
  end

  def get_fulltext_from_pdf
    return nil if (/^application\/pdf/ =~ self.mime_type).nil?
    # puts "ok"
    begin
      reader=PDF::Reader.new(self.filename_with_path)
    rescue
      puts "Errore: #{$!}"
      return {}
    end
    begin
      res=[]
      reader.pages.each do |p|
        puts p.class
        text=p.text
        next if text.blank?
        text.squish!
        res << text
      end
      {fulltext: res.join("\l")}
    rescue
      puts "errore #{$!}"
    end
  end

  # http://bctdoc.selfip.net/documents/30
  def get_bibdata_from_filename
    res={}
    self.filename.split('/').each do |part|
      part.split('#').each do |e|
        next if e.blank?
        tag,data=e.split('_')
        if tag=='mid'
          data.strip!
          puts "tag #{tag} contiene '#{data}'"
          # Causa errore nella formulazione della stringa nome file, ci sono casi in cui
          # il campo "mid" ha un contenuto errato, nel senso che oltre al numero della manifestation_id
          # c'è altro testo che non va considerato
          data = data.split(/ |\./).first.strip
          puts "ora tag #{tag} contiene '#{data}'"
        end
        ts=tag.to_sym
        res[ts]=data if FILENAME_METADATA_TAGS.include?(ts) and !data.blank?
      end
    end
    res[:fname]=self.filename.split(/\W+|_/).sort.uniq.join(' ')
    res
  end

  def write_tags_from_filename(do_save=true)
    puts "in write_tags_from_filename id #{self.id}"
    v=self.get_bibdata_from_filename
    if self.tags.nil?
      # puts "nuovo: v = #{v}"
      self.tags=v.to_xml(:root=>:r,:skip_instruct=>true,:indent=>0)
    else
      puts "tags esiste, aggiungo #{v} A: #{self.tags}"
      doc = REXML::Document.new(self.tags)
      if doc.root.name!='r'
        puts "cambio elemento root da '#{doc.root.name}' a 'r'"
        r=REXML::Element.new('r')
        r.add doc.root
        t=REXML::Document.new(r.to_s)
        puts "t: #{t.to_s}"
        self.tags=t.to_s
      end
      self.edit_tags(v)
    end
    return if do_save==false
    self.save if self.changed?
  end

  def xmltag(tag)
    return nil if self.tags.nil?
    tag=tag.to_s if tag.class==Symbol
    doc = REXML::Document.new(self.tags)
    elem=doc.root.elements[tag]
    return nil if elem.nil?
    res={}
    elem.children.each do |e|
      return e.to_s if e.class==REXML::Text
      puts "e: #{e.inspect} (e.class: #{e.class})"
      res[e.name] = e.text
    end
    res
    # elem.nil? ? nil : elem.text
  end

  def edit_tags(hash)
    if self.tags.nil?
      doc=REXML::Document.new
      doc.add_element('r')
    else
      doc=REXML::Document.new(self.tags)
    end
    puts "in edit_tags, prima: #{doc.to_s}"
    hash.each_pair do |k,v|
      t=k.to_s
      puts "accedo a elemento #{t} che contiene elemento di tipo #{v.class}"
      el = doc.root.elements[t]
      puts "(#{k}=>#{v}) - el: #{el.class} => '#{el.to_s}'"
      doc.root.elements.delete(el) if !el.nil?
      next if v.blank?
      if v.class==String
        el=REXML::Element.new(t)
        el.add_text(v)
        doc.root.elements << el
      else
        puts "Elemento hash da associare a #{t}: #{v.inspect}"
        el = self.add_xlm_elements(t, v)
        doc.root.add_element(el) if !el.elements.empty?
      end
    end
    puts "in edit_tags, dopo: #{doc.to_s}"
    self.tags=doc.to_s
  end

  def delete_blank_tags()
    doc=REXML::Document.new(self.tags)
    # puts "in edit_tags, prima: #{doc.to_s}"
    doc.root.elements.each do |el|
      # puts "el: #{el.class} => '#{el.to_s}'"
      doc.root.elements.delete(el) if el.text.blank?
    end
    # puts "in edit_tags, dopo: #{doc.to_s}"
    self.tags=doc.to_s
  end

  def delete_tag(tag)
    doc=REXML::Document.new(self.tags)
    x=doc.root.elements[tag]
    return if x.nil?
    doc.root.elements.delete(x)
    self.tags=doc.to_s
  end

  def digital_objects_dirscan(dirname, fdout=nil)
    puts "analizzo dir #{dirname}"
    fm=FileMagic.mime

    mp=digital_objects_mount_point
    filecount=0
    Dir[(File.join(dirname,'*'))].each do |entry|
      if File.directory?(entry)
        filecount += digital_objects_dirscan(entry, fdout)
      else
        fstat = File.stat(entry)
        mtype = fm.file(entry)
        if entry =~ /\.mp3$/i and mtype != 'audio/mpeg; charset=binary'
          puts "wrong mime type?: #{entry}"
        end

        entry.sub!(mp,'')
        # puts "File: #{entry}"
        filecount += 1
        if fdout.nil?
          o=DObject.find_or_create_by_filename(entry)
          o.bfilesize=fstat.size
          o.f_ctime=fstat.ctime
          o.f_mtime=fstat.mtime
          o.f_atime=fstat.atime
          o.mime_type=mtype
          o.write_tags_from_filename
          o.save if o.changed?
        else
          fdout.write("#{entry}\t#{fstat.size}\t#{fstat.ctime}\t#{fstat.mtime}\t#{fstat.atime}\t#{mtype}\n")
        end
      end
    end
    # puts "totale files: #{filecount}"
    filecount
  end

  def digital_object_read_metadata
    fm=FileMagic.mime
    fname = File.join(digital_objects_mount_point,filename)
    puts "fname: #{fname}"
    fstat = File.stat(fname)
    self.mime_type = fm.file(fname)
    self.bfilesize = fstat.size
    self.f_ctime = fstat.ctime
    self.f_mtime = fstat.mtime
    self.f_atime = fstat.atime
  end

  def libroparlato_audioclip_basename(ext='mp3')
    "audioclip_#{self.id}.#{ext}"
  end
  def libroparlato_audioclips_basedir
    config = Rails.configuration.database_configuration
    config[Rails.env]["libroparlato_audioclips_basedir"]
  end
  def libroparlato_audioclip_filename(ext='mp3')
    File.join(libroparlato_audioclips_basedir,libroparlato_audioclip_basename(ext))
  end

  def digital_object_create_libroparlato_audioclip(seconds=30,ext='mp3')
    return nil if self.mime_type!='audio/mpeg; charset=binary'
    fn=File.join(digital_objects_mount_point,self.filename)
    target=libroparlato_audioclip_filename(ext)
    return target if File.exists?(target) and File.size(target)>0
    cmd=%Q{/usr/bin/sox "#{fn}" "#{target}" trim 0 #{seconds} fade h 0 0:0:#{seconds} 4}
    # puts cmd
    Kernel.system(cmd)
    mp3=Mp3Info.open(target)
    mp3.tag2.TCOP="Biblioteche civiche torinesi - Servizio libro parlato"
    # mp3.tag2.WOAS="http://clavisbct.comperio.it/"
    mp3.tag2.TCON='Audiobook'
    mp3.tag2.COMM="Preascolto traccia audio"
    mp3.close
    target
  end

  def audioclips_basedir
    config = Rails.configuration.database_configuration
    config[Rails.env]["audioclips_basedir"]
  end

  def add_xlm_elements(tag, hash)
    puts "ok add_xlm_elements:"
    res=REXML::Element.new(tag)
    hash.each_pair do |k,v|
      puts "k: #{k} - v: #{v}"
      next if v.blank?
      el = REXML::Element.new(k.to_s).add_text(v)
      res.elements << el
    end
    puts "res: #{res.to_s}"
    res
  end

  def move(dest_folder_id)
    if self.class==DObject
      puts "sposto #{self.class} con id #{self.id} attualmente in folder #{self.d_objects_folder_id} in folder #{dest_folder_id}"
    else
      puts "sposto #{self.class} con id #{self.id} in folder #{dest_folder_id}"
    end
  end

end
