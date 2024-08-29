# coding: utf-8
class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  # devise :registerable

  devise :database_authenticatable,:registerable, :recoverable, :rememberable, :trackable, :validatable
  # devise :database_authenticatable, :recoverable, :rememberable, :trackable, :validatable

  attr_accessible :email, :password, :password_confirmation, :remember_me, :encrypted_password, :created_at, :updated_at, :role_ids

  has_and_belongs_to_many :roles, order:'name'

  has_and_belongs_to_many :sp_bibliographies, :join_table=>'sp.sp_users', association_foreign_key:'bibliography_id', order:'title'


  has_and_belongs_to_many(:serial_lists, join_table:'public.serial_users',
                          :foreign_key=>'user_id',
                          :association_foreign_key=>'serial_list_id')

  has_one :sbct_supplier, foreign_key:'external_user_id'
  has_many :sbct_lists, foreign_key:'owner_id', order:'hidden desc,label'
  has_many :d_objects_personal_folders

  #def sbct_supplier
  #  sql = "SELECT supplier_id FROM sbct_acquisti.l_suppliers_users WHERE user_id=#{self.id}"
  #end
  def d_objects_folders
    DObjectsFolder.find_by_sql(self.sql_for_d_objects_folders)
  end

  def sql_for_d_objects_folders
    %Q{select dofu.user_id,f.id,f.tags,dofu.mode,case when dofu.pattern is null then f.name else dofu.pattern end as folder_name
      from d_objects_folders_users dofu left join d_objects_folders f on(f.id=dofu.d_objects_folder_id) where user_id=#{self.id} order by folder_name}
  end

  def active_services
    sql = %Q{select s.* from public.roles_services rs join public.roles_users ru 
           using(role_id) where service_id in (select id from public.view_services where root_id=2) and user_id=#{self.id}}
    sql = %Q{select distinct s.name,s.id,s.parent_id from public.roles_services rs
      join public.roles_users ru using(role_id) join public.services s on (s.id=rs.service_id) where user_id=#{self.id} order by name}
    Service.find_by_sql(sql)
  end

  def role?(role)
    if role.class==Array
      myroles = self.roles.collect {|p| p.name}
      role.each do |r|
        return true if myroles.include?(r)
      end
      return false
    else
      return !!self.roles.find_by_name(role.to_s.camelize)
    end
  end

  def to_label
    cl = self.clavis_librarian
    cl.nil? ? self.email : cl.to_label
  end

  # Restituisce la prima lista di proprietà di User, hidden e con allow_uploads true, oppure nil
  # La situazione normale è che un utente abbia una sola lista di caricamento nascosta, che viene considerata lista di default per questa operazione
  def sbct_lista_caricamenti_default
    SbctList.find_by_sql("SELECT * FROM sbct_acquisti.liste WHERE owner_id=#{self.id} AND hidden is true AND allow_uploads is true order by label limit 1").first
  end

  def clavis_librarian
    # ClavisLibrarian.find_by_username(self.email)
    ClavisLibrarian.find_by_sql("SELECT * FROM clavis.librarian where lower(username)=lower(#{self.connection.quote(self.email)})").first
  end

  def clavis_default_library
    cl = self.clavis_librarian
    return nil if cl.nil?
    ClavisLibrary.find(cl.default_library_id)
  end

  def acquisition_manager?
    self.roles.include?(Role.find_by_name('AcquisitionManager'))
  end

  def sbct_budgets
    # return [] if self.id=319
    return [] if self.clavis_librarian.nil?
    libraries=self.clavis_libraries.collect {|l| l.id}
    return [] if libraries==[]
    sql=%Q{
      select b.*,bl.clavis_library_id as library_id from sbct_acquisti.budgets b join sbct_acquisti.l_budgets_libraries bl using(budget_id)
        where not b.locked and clavis_library_id in (#{libraries.join(',')}) order by b.label;
    }
    puts sql
    SbctBudget.find_by_sql(sql)
  end

  def sbct_acquisition_librarian_lists
    return [] if self.clavis_default_library.nil?
    sql = %Q{select 1 as level, id_lista,label,hidden from sbct_acquisti.liste
              where (library_id = #{self.clavis_default_library.id} and owner_id is null) or owner_id=#{self.id}
      order by label}
    SbctList.find_by_sql(sql)
  end

  def sbct_acquisition_librarian_toplist
    raise "User #{self.id} non ha una biblioteca di default" if self.clavis_default_library.nil?
    sql = %Q{select id_lista,level,label,hidden,count(t.id_titolo) from public.pac_lists l
      left join sbct_acquisti.l_titoli_liste t using(id_lista) where l.root_id=5126 and level=1
      and library_id=#{self.clavis_default_library.id}
      and (not hidden or owner_id=#{self.id})
       and l.id_lista!=l.root_id group by l.id_lista,l.level,l.label,l.hidden,l.order_sequence order by l.order_sequence;}

    sql = %Q{select id_lista from public.pac_lists where root_id=5126 and level=1 and library_id=#{self.clavis_default_library.id} and id_lista!=root_id}
    # puts sql
    r=SbctList.find_by_sql(sql).first
    r.nil? ? nil : SbctList.find(r.id)
  end
  
  def clavis_libraries
    return [] if self.clavis_librarian.nil?
    self.clavis_librarian.clavis_libraries
  end

  def clavis_libraries_ids
    self.clavis_libraries.collect{|i| i.id}
  end

  def clavis_libraries_sigle
    ids=self.clavis_libraries.collect {|l| l.id}
    s=ClavisLibrary.library_ids_to_siglebct(ids)
    s= s.reject { |c| c.empty? }
    s.sort.join(', ')
    s.sort
  end

  def bio_iconografico_namespaces
    sql=%Q{SELECT ns.* FROM public.bio_icon_namespaces ns JOIN public.bio_icon_namespaces_users nu using(label) WHERE nu.user_id = #{self.id}}
    BioIconograficoNamespace.find_by_sql(sql)
  end

  def User.add_clavis_librarian(librarian_id, roles_array=[])
    if !ClavisLibrarian.exists?(librarian_id)
      puts "non esiste ClavisLibrarian con librarian_id = #{librarian_id}"
      return nil
    end
    cl = ClavisLibrarian.find(librarian_id)
    puts "Cerco utente con email/username #{cl.username}"
    u = User.find_by_email(cl.username)
    return u if !u.nil?
    email = "#{cl.username}@comperio.it"
    pwd = 'bctorino'
    puts "creazione utente #{librarian_id} con username #{cl.username}"
    roles_array.each do |role_id|
      next if role_id==1
      puts "role #{role_id} ok"
      raise "role #{role_id} not found" if !Role.exists?(role_id)
    end
    user=User.create(:email => email, :password => pwd, :password_confirmation => pwd)
    puts email
    puts pwd
    sql = []
    sql << "BEGIN;"
    roles_array.each do |role_id|
      sql << %Q{insert into roles_users (role_id , user_id) values (#{role_id},#{user.id});}
    end
    sql << "UPDATE users SET email = '#{cl.username}' WHERE id=#{user.id};"
    sql << "COMMIT;"
    sql = sql.join("\n");
    puts sql
    User.connection.execute(sql)
    puts "password per utente #{cl.username} con id #{user.id} : #{pwd}"
    return true
  end

  def User.googledrive_session
    config = Rails.configuration.database_configuration
    username=config[Rails.env]["google_drive_login"]
    passwd=config[Rails.env]["google_drive_passwd"]
    GoogleDrive.login(username, passwd)
  end

  def User.sp_user_select
    sql=%Q{select u.id as key,cl.lastname || ' ' || cl.name as label from public.users u join clavis.librarian cl on(cl.username=u.email) left join public.roles_users ru on (ru.user_id=u.id and ru.role_id=43) where ru is null order by cl.lastname}
    self.connection.execute(sql).collect {|i| [i['label'],i['key']]}
  end

  def User.tutti(params={})
    order = params[:order].blank? ? "l.lastname,l.name" : self.connection.quote_string(params[:order])
    sql = %Q{SELECT u.*,l.librarian_id,l.name,l.lastname,lc.label as siglabib FROM public.users u left join clavis.librarian l
              on (lower(l.username)=lower(u.email))
              LEFT JOIN clavis.library cl on (cl.library_id=l.default_library_id)
              LEFT JOIN sbct_acquisti.library_codes lc on (lc.clavis_library_id=cl.library_id)
          -- WHERE last_sign_in_at notnull
       ORDER BY #{order} #{params[:direction]}}
    User.find_by_sql(sql)
  end
end
