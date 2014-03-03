class ExcelSheet < ActiveRecord::Migration
  def up
    create_table :excel_files do |t|
      t.string :file_name
    end
    create_table :excel_sheets do |t|
      t.string :sheet_name
      t.integer :sheet_number, :null=>false
      t.integer :excel_file_id, :null=>false
    end
    create_table :excel_cells do |t|
      t.integer :cell_row, :null=>false
      t.string :cell_column, :null=>false, :limit=>2
      t.text :cell_content
      t.integer :excel_sheet_id, :null=>false
    end

    execute <<-SQL
      ALTER TABLE excel_sheets ADD CONSTRAINT excel_file_id_fkey
        FOREIGN KEY(excel_file_id) REFERENCES excel_files
         ON UPDATE CASCADE ON DELETE CASCADE;
      CREATE UNIQUE INDEX excel_sheets_idx1 on excel_sheets(sheet_number,excel_file_id);
      ALTER TABLE excel_cells ADD CONSTRAINT excel_sheet_id_fkey
        FOREIGN KEY(excel_sheet_id) REFERENCES excel_sheets
         ON UPDATE CASCADE ON DELETE CASCADE;
    SQL

  end

  def down
    drop_table :excel_cells
    drop_table :excel_sheets
    drop_table :excel_files
  end
end
