class AlterExcelSheet < ActiveRecord::Migration
  def up
    add_column :excel_sheets, :tablename, :string, :limit=>256
    add_index :excel_sheets, :tablename, :unique=>true
  end

  def down
    remove_column :excel_sheets, :tablename
  end
end
