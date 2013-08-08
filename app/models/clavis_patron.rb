# lastmod 21 febbraio 2013

class ClavisPatron < ActiveRecord::Base
  self.table_name='clavis.patron'
  self.primary_key='patron_id'

  has_many :loans, :class_name=>'ClavisLoan', :foreign_key=>'patron_id'

  # Esempio: '70067cfc7e1429cfd7b710a19519d913027eb7a3','158.102.56.204, 158.102.162.9'
  def register_dng_login(opac_secret,client_ip)
    return nil if self.opac_secret!=opac_secret
    DngSession.create(:patron_id=>self.id, :client_ip=>client_ip, :login_time=>Time.now)
  end

  def appellativo
    s = self.gender=='F' ? 'Gent.ma' : 'Gentile'
    "#{s} #{self.name} #{self.lastname}"
  end

  # Attualmente considero abilitati al servizio libro parlato gli utenti contenuti
  # nello scaffale numero 1929 (assurdo, ma funziona)
  def autorizzato_al_servizio_lp
    sql="select true from clavis.shelf_item where shelf_id = 1929 and object_id=#{self.patron_id}"
    r=ClavisPatron.connection.execute(sql).num_tuples
    r == 0 ? false : true
  end

end
