# coding: utf-8
class WorkStation < ActiveRecord::Base
  attr_accessible :clavis_library_id, :id, :location, :processor, :monitor_id

  belongs_to :clavis_library, class_name: 'ClavisLibrary', foreign_key: 'clavis_library_id'

  validates :id, presence: true, uniqueness: true
  validates :clavis_library_id, presence: true
  validates :processor, presence: true

  before_destroy { |record| record.delete_config }

  before_save { |record| record.write_config }
  
  def config_filename
    File.join(WorkStation.config_dir,self.id.to_s)
  end

  def hostname
    "lnx0#{self.id}.ad.comune.torino.it"
  end

  def remote_url
    File.join(WorkStation.remote_url,self.id.to_s)
  end

  def owned_config?
    fname=self.config_filename
    return false if !File.exists?(fname)
    File.read(fname).split("\n").first==WorkStation.tagline ? true : false
  end

  def schedule_action_halt
    # "scheduled_action=Monday-20:00 Tuesday-20:00 Wednesday-20:00 Thursday-20:00 Friday-20:00 Saturday-18:00 action:halt"
    days=[]
    self.clavis_library.week_timetable.each do |d|
      puts "Giorno: #{d.timetable_day.strftime('%A')} - #{d.timetable_open}"
      next if d.time1_end.nil?
      days << "#{d.timetable_day.strftime('%A')}-#{d.time1_end.strftime('%H:%M')}"
    end
    return "# no scheduled actions" if days.size==0
    "scheduled_action=#{days.join(' ')} action:halt"
  end

  def delete_config
    return if !self.owned_config?
    fname=self.config_filename
    puts "cancello file configurazione #{fname}"
    File.delete(fname)
  end

  def print_config
    File.read(self.config_filename)
  end

  def get_config_keyword(keyword)
    return nil if keyword.blank?
    rg=Regexp.new("^#{keyword}")
    File.open(self.config_filename ).each do |line|
      next if (line =~ rg) != 0
      return line[line.index('=')+1..-1]
    end
    nil
  end

  # Riscrive il file di configurazione sostituendo il parametro "configline" che deve
  # essere un array il cui primo elemento è una keyword tra quelle accettate da Porteus
  # e il secondo è il contenuto
  def edit_and_save_config(configline)
    keyword,content=configline
    return if content.blank?

    rg=Regexp.new("^#{keyword}")
    newcontent=[]
    fname=self.config_filename
    debugmsg=[]
    File.open(fname).each do |line|
      # puts line
      debugmsg << "linea: #{line}"
      if (line =~ rg) != 0
        newcontent << line
      else
        newcontent << "#{keyword}=#{content}\n"
      end
    end
    File.write(self.config_filename, newcontent.join)
  end
  
  def managed_bookmarks
    bm = self.get_config_keyword('managed_bookmarks')
    bm.split(' ')
  end

  def homepage
    bm = self.get_config_keyword('homepage')
  end

  def write_config
    fname=self.config_filename
    return if !self.owned_config? and File.exists?(fname)
    tag=WorkStation.tagline
    puts "scrivo in: #{fname}"
    fd=File.open(fname,'w')
    fd.write("#{tag}\n")
    fd.write("# Biblioteca #{self.clavis_library.label} - #{self.location}\n")
    fd.write("# Timestamp ultima scrittura file: #{Time.now}\n\n")
    
    fd.write("hostname=#{self.hostname}\n")
    fd.write("kiosk_config=#{self.remote_url}\n")

    fd.write("#{self.schedule_action_halt}\n\n")

    common=File.read(File.join(WorkStation.config_dir, "common_#{self.processor}.txt"))
    fd.write(common)
    fd.close
  end
  
  def WorkStation.config_dir
    config = Rails.configuration.database_configuration
    config[Rails.env]['workstations_config_dir']
  end
  def WorkStation.remote_url
    config = Rails.configuration.database_configuration
    config[Rails.env]['workstations_remote_url']
  end
  def WorkStation.tagline
    '# File di configurazione per Porteus-Kiosk generato da http://clavisbct.comperio.it/work_stations'
  end

end
