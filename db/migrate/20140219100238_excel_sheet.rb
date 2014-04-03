class ExcelSheet < ActiveRecord::Migration
  def up
    create_table :excel_files do |t|
      t.string :file_name
      t.integer :file_size
      t.date   :updated_at
    end
    create_table :excel_sheets do |t|
      t.string :sheet_name
      t.integer :sheet_number, :null=>false
      t.integer :excel_file_id, :null=>false
      t.text :columns
    end

    execute <<-SQL
      ALTER TABLE excel_sheets ADD CONSTRAINT excel_file_id_fkey
        FOREIGN KEY(excel_file_id) REFERENCES excel_files
         ON UPDATE CASCADE ON DELETE CASCADE;
      CREATE UNIQUE INDEX excel_sheets_idx1 on excel_sheets(sheet_number,excel_file_id);
      CREATE SCHEMA excel_files_tables;
    SQL

  end

  def down
    execute <<-SQL
      DROP TABLE excel_sheets,excel_files CASCADE;
      DROP SCHEMA excel_files_tables CASCADE;
    SQL
  end
end
