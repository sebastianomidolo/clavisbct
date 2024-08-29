# coding: utf-8
class BibSection < ActiveRecord::Base
  attr_accessible :name, :library_id, :external
  # has_many :collocazioni, class_name:'SchemaCollocazioniCentrale'
  has_many :locations
  belongs_to :clavis_library, foreign_key:'library_id'

  def to_label
    # "#{self.clavis_library.to_label} #{self.name}"
    self.name
  end

  # In realtà questi parametri non sembrano avere senso in questo contesto
  def sql_conditions(ignore_locked=false,table_alias='cl')
    cond = []
    self.collocazioni.each do |c|
      cond << "(#{c.conditions_for_update_centrale_locations(ignore_locked,table_alias)})"
    end
    "(#{cond.join("\n OR ")})"
  end

end
