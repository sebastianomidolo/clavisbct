class AttachmentsAddField < ActiveRecord::Migration
  def up
    add_column :attachments, :folder, :string, :limit=>128
  end

  def down
    remove_column :attachments, :folder
  end
end
