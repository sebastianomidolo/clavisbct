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

end
