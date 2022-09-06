# coding: utf-8

class SbctOrder < ActiveRecord::Base
  self.table_name='sbct_acquisti.orders'
  self.primary_keys = [:supplier_id, :row_number]


  def calcola_copie_ordinate
    sigle=ClavisLibrary.siglebct
    cnt = 0
    self.note.split(' ').each do |sigla|
      next if sigle[sigla.downcase.to_sym].nil?
      puts "sigla: #{sigla}"
      cnt +=1
    end
    self.numcopie=cnt
    self.save
  end
  
  def SbctOrder.calcola_copie_ordinate
    # SbctOrder.where('numcopie is null').each do |r|
    SbctOrder.all.each do |r|
      r.calcola_copie_ordinate
    end
  end

end
