class CipesCedoRecord < ActiveRecord::Base
  self.table_name='cipes.b_cedogen'
  self.primary_key = 'mfn'

  def cedo_url
    "http://www.cipespiemonte.it/cedo/schmul.php?mfn1=#{self.id}"
  end

  def self.search_all(words,params={})
    return [] if words.nil?
    cond=[]
    ts=self.connection.quote_string(words.split.join(' & '))
    CipesCedoRecord.columns_hash.each do |k,v|
      next if ![:string,:text].include?(v.type)
      cond << "to_tsvector('simple', #{k}) @@ to_tsquery('simple', '#{ts}')"
    end
    sql=%Q{SELECT * FROM #{self.table_name} WHERE #{cond.join(' OR ')} ORDER BY lower(titolo)}
    self.paginate_by_sql(sql,page:params[:page],per_page:params[:per_page])
  end
end
