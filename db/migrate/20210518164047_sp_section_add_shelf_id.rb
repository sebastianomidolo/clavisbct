class SpSectionAddShelfId < ActiveRecord::Migration
  def up
    execute <<-SQL
       ALTER TABLE sp.sp_sections ADD COLUMN clavis_shelf_id integer;
    SQL
  end

  def down
    execute <<-SQL
       ALTER TABLE sp.sp_sections DROP COLUMN clavis_shelf_id;
    SQL
  end
end
