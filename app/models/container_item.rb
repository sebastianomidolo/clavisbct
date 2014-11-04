class ContainerItem < ActiveRecord::Base
  # attr_accessible :title, :body
  belongs_to :container, foreign_key: :label, primary_key: :label
  belongs_to :clavis_item, foreign_key: :item_id
  belongs_to :clavis_manifestation, foreign_key: :manifestation_id


  def collocazione
    if self.clavis_item.nil?
    else
      self.clavis_item.collocation
    end
  end

  def google_drive_url
    return nil if self.google_doc_key.nil?
    "https://docs.google.com/spreadsheets/d/#{self.google_doc_key}"
  end
end
