class SpItem < ActiveRecord::Base
  self.table_name='sp.sp_items'

  attr_accessible :bibliography_id, :item_id, :bibdescr, :updated_at, :section_number, :colldec, :sbn_bid, :created_at, :mainentry, :collciv, :sigle, :sortkey, :note

  belongs_to :sp_bibliography, :foreign_key=>'bibliography_id'

  def sp_section
    return nil if self.section_number.nil?
    SpSection.find_by_number_and_bibliography_id(self.section_number,self.bibliography_id)
  end

  def thesection
    return '' if self.section_number.nil?
    self.sp_section.title
  end

  def collocazioni
    self.collciv
  end

  def senza_parola_item_path
    "http://biblio.comune.torino.it/ProgettiCivica/SenzaParola/typo.cgi?id=#{self.bibliography_id}&skid=#{self.item_id}&rm=edit"
  end

  def SpItem.ricollocati_a_scaffale_aperto
    sql=%Q{select ci.custom_field1 as ex_collocazione,ci.section,ci.collocation,spi.*,
           spb.title as bibliography_title from sp.sp_items spi join clavis.item ci
        on (spi.collciv=substr(custom_field1,4))
       join sp.sp_bibliographies spb on(spb.id=spi.bibliography_id) where ci.section ~ '^CC'
      and ci.owner_library_id=2 order by spb.title, spi.sortkey}
    # SpItem.connection.execute(sql).to_a
    SpItem.find_by_sql(sql)
  end
end
