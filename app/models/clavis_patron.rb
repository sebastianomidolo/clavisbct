# -*- coding: utf-8 -*-

class ClavisPatron < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  # devise :database_authenticatable, :registerable, :recoverable, :rememberable, :trackable, :validatable
  devise :database_authenticatable, :rememberable, :encryptable, :encryptor=>:sha1, :stretches=>10

  alias_attribute :encrypted_password, :opac_secret
  # alias_attribute :password_salt, :opac_secret

  # Setup accessible (or protected) attributes for your model
  # attr_accessible :email, :password, :password_confirmation, :remember_me
  attr_accessible :opac_username, :opac_secret

  self.table_name='clavis.patron'
  self.primary_key='patron_id'

  has_many :loans, :class_name=>'ClavisLoan', :foreign_key=>'patron_id'
  has_many :dng_sessions, :foreign_key=>'patron_id'

  # Esempio: '70067cfc7e1429cfd7b710a19519d913027eb7a3','158.102.56.204, 158.102.162.9'
  def register_dng_login(opac_secret,client_ip)
    return nil if self.opac_secret!=opac_secret
    dng=DngSession.create(:patron_id=>self.id, :client_ip=>client_ip, :login_time=>Time.now)
    dng.log_session_id
  end

  def appellativo
    s = self.gender=='F' ? 'Gent.ma' : 'Gentile'
    "#{s} #{self.name} #{self.lastname}"
  end

  def to_label
    "#{self.name} #{self.lastname}"
  end

  def autorizzato_al_servizio_lp
    self.loan_class=='@' ? true : false
  end

  def autorizzato_download_pdf(clavis_manifestation)
    # Esempio su manifestation 571777 e uid 52697 cioè:
    # reload!;ClavisPatron.find(52697).autorizzato_download_pdf(ClavisManifestation.find(571777))
    # Esempio di pdf libero (in quanto composto da oggetti a loro volta liberi):
    # reload!;ClavisPatron.find(8959).autorizzato_download_pdf(ClavisManifestation.find(219606))
    aut=true
    scadenza=nil
    return false if clavis_manifestation.d_objects.size==0
    dob=clavis_manifestation.d_objects.first
    dirname=File.dirname(dob.filename)
    clavis_manifestation.d_objects.each do |o|
      # Provvisorio: solo i files in doc_delivery sono autorizzabili, gli altri no in ogni caso (per ora)
      if !(/^doc/ =~  o.filename)
        puts "filename #{o.filename}"
        aut=false
      end
      next if o.access_right_id==0
      return false if o.access_right_id==2
      return false if o.access_right_id==1
      mid=o.xmltag(:mid).to_i
      if mid==0
        # puts o.filename
      end
      next if mid!=clavis_manifestation.id
      sc = o.xmltag(:sc)
      next if sc.blank?
      uid=o.xmltag(:uid).to_i
      puts "uid: #{uid}"
      # uid=8959; # debug only
      if uid!=self.id and uid!=0
        aut=false
        # <sc>mm12</sc>
        mesi = sc.gsub('mm','').split[0].to_i
        # puts "mesi: #{mesi}"
        # o.tags="<r><dc>2012-08</dc></r>"
        dc = o.xmltag(:dc)
        if dc.blank?
          dc = o.f_mtime
        else
          dc_anno,dc_mese=dc.split('-')
          # puts dc_anno
          # puts dc_mese
          dc = Time.new(dc_anno, dc_mese)
        end
        # puts "data_caricamento_file: #{dc}"
        t1 = dc + mesi.months
        # puts t1
        scadenza = t1 if scadenza.nil? or scadenza > t1
      end
    end
    return false if scadenza.nil? and aut==false
    # puts "scadenza: #{scadenza}"
    if scadenza.nil?
      # In realtà è un po' troppo permissivo: potrebbero esserci e ci sono casi
      # in cui il semplice fatto che non sia indicata una scadenza dei diritti
      # non implica che i diritti ci siano
      true
    else
      Time.now >= scadenza
    end
  end

  def closed_stack_item_requests
    time_limit = "request_time-now() > interval '60 minutes ago'"
    ActiveRecord::Base.connection.execute("SET timezone to 'UTC'")
    sql=%Q{SELECT DISTINCT ir.* FROM closed_stack_item_requests ir
        JOIN dng_sessions s ON(ir.dng_session_id=s.id)
              WHERE #{time_limit} ORDER BY request_time;}
    ClosedStackItemRequest.find_by_sql(sql)
  end
  def closed_stack_item_request_pdf(dng_session)
    inputdata=[]
    inputdata << self
    inputdata << dng_session
    lp=LatexPrint::PDF.new('closed_stack_item_request', inputdata)
    lp.makepdf
  end

  def ClavisPatron.clavis_url(id)
    config = Rails.configuration.database_configuration
    host=config[Rails.env]['clavis_host']
    "#{host}/index.php?page=Circulation.PatronViewPage&id=#{id}"
  end

end
