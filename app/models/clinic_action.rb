# coding: utf-8
class ClinicAction < ActiveRecord::Base
  attr_accessible :reparto, :azione, :description, :attivo, :sql

  validates :reparto, presence: true
  validates :azione, presence: true
  before_save :removeblanks

  def removeblanks
    self.reparto=nil if self.reparto.blank?
    self.azione=nil if self.azione.blank?
    self.sql=nil if self.sql.blank?
    self.reparto = self.reparto.strip
  end
 
  def to_label
    "#{self.reparto}/#{self.azione} - #{self.description}"
    self.description.blank? ? '[senza descrizione]' : self.description
  end

  def sql_secure
    return if self.sql.blank?
    self.sql.gsub(/update|delete|create|drop/i, "\nREMOVED COMMAND")
  end

  def sql_exec_command
    s = self.sql_secure
    if s!=self.sql
      return "Codice non eseguito perché non sicuro"
    end
    act = self.azione.strip
    cl = ClavisImport::Clinic.new
    if !cl.respond_to?(act)
      return "In ClavisImport::Clinic non esiste l'azione #{act}"
    end
    begin
      cl.send(act,s)
    rescue
      "Errore da #{act}:\n#{$!}"
    end
  end

  def ClinicAction.nuova
    self.create({reparto:'nuovo',azione:'nuova'})
  end

end
