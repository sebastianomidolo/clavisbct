class ServiceDocType < ActiveRecord::Base

  has_many :service_docs

  def to_label
    self.label
  end
end
