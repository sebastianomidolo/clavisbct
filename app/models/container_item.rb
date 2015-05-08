class ContainerItem < ActiveRecord::Base
  attr_accessible :created_by, :manifestation_id, :item_title, :container_id, :item_id, :consistency_note_id
  # belongs_to :container, foreign_key: :label, primary_key: :label
  belongs_to :container
  belongs_to :clavis_item, foreign_key: :item_id
  belongs_to :clavis_manifestation, foreign_key: :manifestation_id

  def collocazione
    if self.clavis_item.nil?
    else
      self.clavis_item.collocation
    end
  end

end
