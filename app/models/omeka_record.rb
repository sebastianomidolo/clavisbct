class OmekaRecord < ActiveRecord::Base
  self.abstract_class = true

  def title
    puts self.class
    x=self.element_texts.where(:element_id=>50).first
    x.class==OmekaElementText ? x.text : nil
  end

  def title= string
    puts "titolo attuale: #{self.title}"
    x=self.element_texts.where(:element_id=>50).first
    if x.class==OmekaElementText
      puts "titolo attuale: #{self.title}"
      x.text=string
      x.save
    else
      record_type=self.class.to_s.sub('Omeka','')
      puts "creare text per #{record_type}"
      sql=%Q{INSERT INTO #{OmekaElementText.table_name} (record_id, record_type, element_id, text, html)
       VALUES (#{self.id}, '#{record_type}', 50, #{self.connection.quote(string)}, false);}
      self.connection.execute(sql)
    end

  end

end
