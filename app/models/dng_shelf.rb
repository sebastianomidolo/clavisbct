require 'php_serialize'

class DngShelf < ActiveRecord::Base
  self.table_name='dng."Shelf"'
  self.primary_key = 'ID'

  # domain potrebbe essere "MLOL" (o altro); di default e' "catalog"
  def clavis_manifestations_ids(domain='catalog')
    return [] if self.ClassName!='ManifestationsShelf'
    a=PHP.unserialize(self.SerializedData)
    return [] if a.nil?
    a = a["manifestations"]
    r = Regexp.new("sbct:#{domain}:(.*)")
    if a.class==Hash
      a=a.values.collect {|x| x =~ r; $1}
    else
      # Array
      a=a.collect {|x| x =~ r; $1}
    end
    a.compact
  end

  def clavis_manifestations(domain='catalog')
    ClavisManifestation.find(self.clavis_manifestations_ids(domain))
  end

  def items_barcodes
    ids=self.clavis_manifestations_ids('catalog')
    return [] if ids.size==0
    ids
    sql=%Q{SELECT DISTINCT barcode FROM #{ClavisItem.table_name} WHERE manifestation_id IN(#{ids.join(',')});}
    ClavisItem.connection.execute(sql).to_a.collect {|b| b['barcode']}
  end
end
