class BioIconograficoTopic < ActiveRecord::Base
  attr_accessible :tags

  has_many :attachments, :as => :attachable
  has_many :bio_iconografico_cards, :through => :attachments, :source => :d_object
  
  def edit_tags(hash)
    self.tags={}.to_xml(root:'r',:skip_instruct => true, :indent => 0) if self.tags.blank?
    doc=REXML::Document.new(self.tags)
    hash.each_pair do |k,v|
      t=k.to_s
      el = doc.root.elements[t]
      doc.root.elements.delete(el) if !el.nil?
      el=REXML::Element.new(t)
      el.add_text(v)
      doc.root.elements << el
    end
    self.tags=doc.to_s
  end
  def xmltag(tag)
    tag=tag.to_s if tag.class==Symbol
    return nil if self.tags.nil?
    doc = REXML::Document.new(self.tags)
    elem=doc.root.elements[tag]
    elem.nil? ? nil : elem.text
  end

  def intestazione=(t) self.edit_tags(intestazione:t) end
  def lettera=(t) self.edit_tags(l:t) end
  def numero=(t) self.edit_tags(n:t) end

  def altri_link=(t) self.edit_tags(altri_link:t) end
  def data_morte=(t) self.edit_tags(data_morte:t) end
  def data_nascita=(t) self.edit_tags(data_nascita:t) end
  def esistenza_in_vita=(t) self.edit_tags(esistenza_in_vita:t) end
  def luoghi_di_soggiorno=(t) self.edit_tags(luoghi_di_soggiorno:t) end
  def luoghi_visitati=(t) self.edit_tags(luoghi_visitati:t) end
  def luogo_morte=(t) self.edit_tags(luogo_morte:t) end
  def luogo_nascita=(t) self.edit_tags(luogo_nascita:t) end
  def note=(t) self.edit_tags(nt:t) end
  def qualificazioni=(t) self.edit_tags(qualificazioni:t) end
  def seqnum=(t) self.edit_tags(seqnum:t) end
  def var1=(t) self.edit_tags(var1:t) end
  def var2=(t) self.edit_tags(var2:t) end
  def var3=(t) self.edit_tags(var3:t) end
  def var4=(t) self.edit_tags(var4:t) end
  def var5=(t) self.edit_tags(var5:t) end


  def intestazione() self.xmltag('intestazione') end
  def lettera() self.xmltag('l') end
  def numero() self.xmltag('n') end

  def altri_link() self.xmltag('altri_link') end
  def data_morte() self.xmltag('data_morte') end
  def data_nascita() self.xmltag('data_nascita') end
  def esistenza_in_vita() self.xmltag('esistenza_in_vita') end
  def luoghi_di_soggiorno() self.xmltag('luoghi_di_soggiorno') end
  def luoghi_visitati() self.xmltag('luoghi_visitati') end
  def luogo_morte() self.xmltag('luogo_morte') end
  def luogo_nascita() self.xmltag('luogo_nascita') end
  def note() self.xmltag('nt') end
  def qualificazioni() self.xmltag('qualificazioni') end
  def seqnum() self.xmltag('seqnum') end
  def var1() self.xmltag('var1') end
  def var2() self.xmltag('var2') end
  def var3() self.xmltag('var3') end
  def var4() self.xmltag('var4') end
  def var5() self.xmltag('var5') end

end
