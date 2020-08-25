# coding: utf-8
class Manoscritto < ActiveRecord::Base
  self.table_name='mss.catalogo_ag'
  attr_accessible :titolo, :note
  before_save :update_d_objects_folder_metadata
  
  has_many :attachments, :as => :attachable


  def to_label
    "#{self.collocazione} #{self.titolo}"
  end

  def browse_object(cmd)
    sortkey=self.connection.quote_string(self.sortkey)
    case cmd
    when 'prev'
      cond = "where sortkey < '#{sortkey}' order by lower(sortkey) desc"
    when 'next'
      cond = "where sortkey > '#{sortkey}' order by lower(sortkey)"
    when 'first'
      cond = "order by lower(sortkey)"
    when 'last'
      cond = "order by lower(sortkey) desc"
    else
      raise "browse_object('prev'|'next'|'first'|'last')"
    end
    sql=%Q{select * from #{Manoscritto.table_name} #{cond} limit 1}
    Manoscritto.find_by_sql(sql).first
  end


  def dvd_originale
    return nil if self.pdf_file.nil?
    sql=%Q{select * from mss.pdf_files where id=#{self.pdf_file}}
    self.connection.execute(sql).to_a.first
  end

  # basedir per esempio: "bct/mss/dvd"
  # bct/mss/dvd/T0020/00000008
  def d_objects_folder(basedir='bct/mss/dvd')
    dvd=self.dvd_originale
    return nil if dvd.nil?
    target = format 'T%04d', dvd['numero_dvd']
    path=File.dirname(dvd['path'])
    n=File.join(basedir,target,path)
    DObjectsFolder.find_by_name(n)
  end

  def extended_title
    "#{self.collocazione} #{self.autore} #{self.titolo}"
  end

  def update_d_objects_folder_metadata
    f = self.d_objects_folder
    return if f.nil?
    f.x_ti=self.extended_title
    f.save if f.changed?
  end

  def elimina_spazi_multipli
    self.attribute_names.each do |a|
      next if self[a.to_sym].class != String
      # puts "#{a}: \"#{self[a.to_sym]}\""
      self[a.to_sym] = self[a.to_sym].squeeze(' ').strip
      # puts "#{a}: \"#{self[a.to_sym]}\""
    end
    if self.changed?
      puts "#{self.id} modificato"
      self.save
    end
    true
  end

  def Manoscritto.metadatizza_d_objects_folders
    self.all.each {|m| m.update_d_objects_folder_metadata}
    true
  end
  
  # Aggiustamento encoding per table mss.catalogo_ag dove ho rilevato problemi di codifica, per esempio
  # è presente il carattere "é" mentre in altri record lo stesso carattere è espresso come "Ã©".
  def Manoscritto.fix_utf8
    chars={'Ã©':'é',
           'Ã¨':'è',
           'Ã¹':'ù',
           'Ã²':'ò',
           'Ã¬':'ì',
           'Ã§':'ç',
           'àª':'ê',
           'à¼':'ü',
           'à¯':'ï',
          }
    self.column_names.sort.each do |c|
      next if [
          'area_di_lavoro',
          'bid',
          'coll_prec',
          'collocazione',
          'dimensioni',
          'ingresso',
          'id',
          'livello_descr',
          'numero_catena',
          'numero_catena',
          'pdf_file',
          'provenienza',
          'restauro',
          'status',
        ].include?(c)

      chars.keys.each do |k|
        sql="UPDATE #{self.table_name} set #{c}=replace(#{c},'#{k}','#{chars[k]}') where id in (select id from #{self.table_name} where #{c} ~ '#{k}');"
        self.connection.execute(sql)
      end
      sql="UPDATE #{self.table_name} set #{c}=replace(#{c},'Ã','à') where id in (select id from #{self.table_name} where #{c} like '%Ã%');"
      self.connection.execute(sql)
    end
    sql=%Q{update mss.catalogo_ag set titolo=replace(titolo,'+++','') where id in (select id from mss.catalogo_ag where titolo like '%+++%');
           update mss.catalogo_ag set titolo=replace(titolo,'+.+','') where id in (select id from mss.catalogo_ag where titolo like '%+.+%');
           update mss.catalogo_ag set titolo=replace(titolo,'  ',' ') where id in (select id from mss.catalogo_ag where titolo like '%  %');}
      self.connection.execute(sql)    
  end

  def Manoscritto.sortkey_update
    self.connection.execute %Q{
      update mss.catalogo_ag
      set sortkey = (case when chiaveautore is null then chiavetitolo else chiaveautore || ' ' || chiavetitolo end);}
  end

end
