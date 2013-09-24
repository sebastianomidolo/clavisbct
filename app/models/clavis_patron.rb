# -*- coding: utf-8 -*-
# lastmod 21 febbraio 2013

class ClavisPatron < ActiveRecord::Base
  self.table_name='clavis.patron'
  self.primary_key='patron_id'

  has_many :loans, :class_name=>'ClavisLoan', :foreign_key=>'patron_id'
  has_many :dng_sessions, :foreign_key=>'patron_id'

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
    return true if self.loan_class=='@'
    sql="select true from clavis.shelf_item where shelf_id = 1929 and object_id=#{self.patron_id}"
    r=ClavisPatron.connection.execute(sql).num_tuples
    r == 0 ? false : true
  end

  def autorizzato_download_pdf(clavis_manifestation)
    # Esempio su manifestation 571777 e uid 52697 cioè:
    # reload!;ClavisPatron.find(52697).autorizzato_download_pdf(ClavisManifestation.find(571777))
    # Esempio di pdf libero (in quanto composto da oggetti a loro volta liberi):
    # reload!;ClavisPatron.find(8959).autorizzato_download_pdf(ClavisManifestation.find(219606))
    aut=true
    scadenza=Time.now + 1.hour
    return false if clavis_manifestation.d_objects.size==0
    dob=clavis_manifestation.d_objects.first
    dirname=File.dirname(dob.filename)
    clavis_manifestation.d_objects.each do |o|
      next if o.access_right_id==0
      mid=o.xmltag(:mid).to_i
      if mid==0
        puts o.filename
      end
      next if mid!=clavis_manifestation.id
      uid=o.xmltag(:uid).to_i
      # puts "uid: #{uid}"
      # uid=8959; #debug only
      aut=false if uid!=self.id
      sc = o.xmltag(:sc)
      next if sc.blank?
      mesi = sc.split[0].to_i
      t1 = o.f_mtime + mesi.months
      scadenza = t1 if scadenza > t1
    end
    return true if aut==true
    Time.now >= scadenza
  end

end
