class AlterAttachemnts < ActiveRecord::Migration
  def up
    execute <<-SQL
      ALTER TABLE public.attachments ALTER COLUMN "folder" type varchar(512);
    SQL
  end

  def down
  end
end
