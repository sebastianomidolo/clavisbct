class AlterExcelFile < ActiveRecord::Migration
  def up
    execute "alter TABLE excel_files ALTER COLUMN updated_at type timestamp"
  end

  def down
  end
end
