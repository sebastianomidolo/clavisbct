include SoapClient

class ClavisShelf < ActiveRecord::Base
  self.table_name='clavis.shelf'
  self.primary_key = 'shelf_id'

  def clavis_url
    ClavisShelf.clavis_url(self.id)
  end

  def ClavisShelf.shelf_select(library_id=nil, shelf_itemtype='manifestation',visibility:"'B','D','E','F'")
    if !library_id.nil?
      self.connection.execute("DELETE FROM clavis.shelf WHERE shelf_itemtype = 'manifestation' AND library_id = #{library_id}")
      ClavisShelf.insert_manifestation_shelves_for_library(library_id)
    end
    cond = library_id.nil? ? '' : "and s.library_id=#{library_id}"
    sql=%Q{select '(' || shelf_id || ') ' || shelf_name || ' (' || cl.username || ')' as label,shelf_id as key
              from clavis.shelf as s join clavis.librarian cl using(librarian_id)
         where shelf_itemtype='#{shelf_itemtype}' AND shelf_status IN(#{visibility}) #{cond} order by shelf_name;}
    self.connection.execute(sql).collect {|i| [i['label'],i['key']]}
  end

  def ClavisShelf.soap_get_records_in_shelf(shelf_id)
    client = SoapClient::get_wsdl('catalog')
    r = client.call(:get_records_in_shelf, message: {shelf_id:shelf_id})
    return [] if r.body[:get_records_in_shelf_response][:return].nil?
    res=r.body[:get_records_in_shelf_response][:return][:item]
    if !res.nil?
      res = [res.to_s] if res.class == Nori::StringWithAttributes
      sql = %Q{DELETE FROM clavis.shelf_item where shelf_id=#{shelf_id} and object_class='manifestation';
         INSERT INTO clavis.shelf_item (shelf_id,object_id,object_class) VALUES}
      inserts = []
      inserts << res.map {|v| "(#{shelf_id},#{v.to_i},'manifestation')"}
      self.connection.execute "#{sql} #{inserts.join(',')} ON CONFLICT(shelf_id, object_id, object_class) DO NOTHING;"  
    end
  end

  def ClavisShelf.insert_manifestation_shelves_for_library(library_id)
    sql = ClavisShelf.soap_get_shelves_for_library_sql(library_id)
    puts "sql: #{sql}"
    return if sql.blank?
    self.connection.execute(ClavisShelf.soap_get_shelves_for_library_sql(library_id))
  end

  def ClavisShelf.soap_get_shelves_for_library_sql(library_id)
    client = SoapClient::get_wsdl('catalog')
    r = client.call(:get_shelves_for_library, message: {library_id:library_id})
    return if r.body[:get_shelves_for_library_response][:return].nil?
    res=r.body[:get_shelves_for_library_response][:return][:item]
    return if res.nil?
    sql = nil
    inserts = []
    res.each do |e|
      if e.class == Array
        next if e.first != :item
        keys = e[1].collect {|i| i[:key].snakecase}
        values = e[1].collect {|i| i[:value]}
      else
        keys = e[:item].collect {|i| i[:key].snakecase}
        values = e[:item].collect {|i| i[:value]}
      end
      sql = "INSERT INTO #{self.table_name} (#{keys.join(',')}) VALUES" if sql.nil?
      inserts << "(#{values.map {|v| self.connection.quote(v)}.join(',')})"
    end
    "#{sql} #{inserts.join(',')} ON CONFLICT(shelf_id) DO NOTHING;"
  end

  def ClavisShelf.clavis_url(shelf_id)
    config = Rails.configuration.database_configuration
    host=config[Rails.env]['clavis_host']
    "#{host}/index.php?page=Communication.ShelfViewPage&id=#{shelf_id}"
  end

end
