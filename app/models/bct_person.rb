class BctPerson < ActiveRecord::Base
  self.table_name='letterebct.people'
  attr_accessible :denominazione
  has_many :lettere_inviate, :class_name=>'BctLetter', :foreign_key=>'mittente_id'
  has_many :lettere_ricevute, :class_name=>'BctLetter', :foreign_key=>'destinatario_id'

  has_many :destinatari, :class_name=>'BctPerson', :through=>:lettere_inviate,
    :source=>:destinatario, :uniq=>true, :order=>'denominazione'
  has_many :mittenti, :class_name=>'BctPerson', :through=>:lettere_ricevute,
    :source=>:mittente, :uniq=>true, :order=>'denominazione'


  def luoghi_invio
    sql=%Q{SELECT DISTINCT p.* FROM #{BctPlace.table_name} p, #{BctLetter.table_name} l
            WHERE #{id} IN (l.mittente_id) AND p.id=l.placefrom_id ORDER BY p.denominazione}
    BctPlace.find_by_sql sql
  end
  def luoghi_ricezione
    sql=%Q{SELECT DISTINCT p.* FROM #{BctPlace.table_name} p, #{BctLetter.table_name} l
            WHERE #{id} IN (l.destinatario_id) AND p.id=l.placeto_id ORDER BY p.denominazione}
    BctPlace.find_by_sql sql    
  end

  def numero_lettere
    BctLetter.count_by_sql "SELECT count(*) FROM #{BctLetter.table_name} WHERE #{self.id} IN(mittente_id,destinatario_id)"
  end

  def info_lettere_ricevute
    l = self.lettere_ricevute.size
    return nil if l==0
    p = self.luoghi_ricezione.size
    (l==1 ? "Una lettera ricevuta" : "#{l} lettere ricevute") << " in " <<
      (p==1 ? " " : "#{p} luoghi: ") <<
      (self.luoghi_ricezione.collect {|l| l.denominazione}).join(' ; ')
  end

  def info_destinatari
    self.destinatari.collect{|p| p.denominazione}.join(' ; ')
  end
  def info_mittenti
    self.mittenti.collect{|p| p.denominazione}.join(' ; ')
  end

  def BctPerson.lista_con_lettere(page=1,conditions='',per_page=40)
    cond=conditions.blank? ? '' : "WHERE #{conditions}"
    sql=%Q{SELECT p.id,p.denominazione, count(l.id) AS "numdocs" FROM #{BctPerson.table_name} p
            LEFT JOIN #{BctLetter.table_name} l ON(p.id IN (l.mittente_id,l.destinatario_id)) #{cond}
            GROUP BY p.id,p.denominazione HAVING count(l.id)>0 ORDER BY count(l.id) desc,lower(p.denominazione)}
    self.paginate_by_sql(sql, per_page:per_page, page:page)
  end


end
