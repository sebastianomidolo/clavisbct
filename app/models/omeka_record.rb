class OmekaRecord < ActiveRecord::Base
  self.abstract_class = true

  def title
    x=self.element_texts.where(element_id:50).first
    x.class==OmekaElementText ? x.text : nil
  end

  def title= string
    self.set_element(50,string)
  end

  def clavis_manifestation_id= string
    self.set_element(43,string)
  end

  
  def set_element(element_id,string)
    x=self.get_elements(element_id).first
    if x.class==OmekaElementText
      x.text=string
      x.save
    else
      record_type=self.class.to_s.sub('Omeka','')
      # puts "creare text per #{record_type}"
      sql=%Q{INSERT INTO #{OmekaElementText.table_name} (record_id, record_type, element_id, text, html)
       VALUES (#{self.id}, '#{record_type}', #{element_id}, #{self.connection.quote(string)}, false);}
      self.connection.execute(sql)
    end
  end

  
  def get_elements(element_id)
    self.element_texts.where(element_id:element_id)
  end

  def get_element(element_id)
    x=self.element_texts.where(element_id:element_id).first
    x.nil? ? nil : x.text
  end

  # Assumo che un numero intero maggiore di zero sia una manifestation_id di Clavis
  def clavis_manifestation_id
    self.get_elements(43).each do |e|
      i=e.text.to_i
      return i if i.is_a? Integer and i!=0
    end
    nil
  end
  
  def sbn_bid
    self.get_elements(43).each do |e|
      i = e.text.to_i
      next if i!=0
      return e.text if e.text.size==10
    end
  end


end
