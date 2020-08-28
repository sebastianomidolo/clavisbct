# coding: utf-8
class SerialSubscription < ActiveRecord::Base
  self.primary_keys = :serial_title_id, :library_id
  attr_accessible :serial_title_id,:library_id,:prezzo,:note
  before_save :set_date_updated
  
  belongs_to :serial_title
  belongs_to :clavis_library, foreign_key: :library_id

  def set_date_updated
    self.date_updated=Time.now
  end

  def SerialSubscription.associa_copie_multiple(libs,nums)
    res=[]
    n=nums.split(',')
    i=0
    libs.split(', ').each do |l|
      res << (n[i].to_i > 1 ? "#{l} (#{n[i]} copie)" : l)
      i+=1
    end
    res.join(', ')
  end

  def SerialSubscription.copie_per_bib(library_id, library_ids, nums)
    res=0, i=0, n=nums.split(',')
    library_ids.split(',').each do |id|
      res = n[i].to_i and break if id.to_i==library_id
      i+=1
    end
    res
  end
end

