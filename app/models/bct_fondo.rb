class BctFondo < ActiveRecord::Base
  self.table_name='letterebct.fondi'
  has_many :bct_letters, :foreign_key=>:fondo_id

  belongs_to :bct_fondo, :foreign_key=>:parent_id
  has_many :bct_fondi, :class_name=>'BctFondo', :foreign_key=>:parent_id


  def to_label
    s="#{self.denominazione}"
    s << " (#{self.bct_fondo.denominazione})" if !self.bct_fondo.nil?
    s
  end

  def BctFondo.elenco
    BctFondo.find_by_sql "select * from #{BctFondo.table_name} f order by f.denominazione"
  end


end
