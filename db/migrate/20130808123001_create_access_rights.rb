class CreateAccessRights < ActiveRecord::Migration
  def up
    create_table :access_rights,:id=>false do |t|
      t.integer :code, :null=>false, :limit=>1
      t.string :label, :null=>false, :limit=>32
      t.string :description, :limit=>255
    end
    add_column :d_objects, :access_right_id, :integer, :limit=>1

    execute <<-SQL
      ALTER TABLE access_rights add primary key(code);
      CREATE UNIQUE INDEX access_rights_label_idx on access_rights(label);
      ALTER TABLE d_objects ADD CONSTRAINT access_right_id_fkey
        FOREIGN KEY(access_right_id) REFERENCES access_rights
         ON UPDATE CASCADE ON DELETE SET NULL;
      CREATE INDEX access_right_id_idx on d_objects(access_right_id);
      INSERT INTO access_rights (code, label, description) VALUES
          (0,'Libero','Accesso libero senza alcuna restrizione');
      INSERT INTO access_rights (code, label, description) VALUES
          (1,'Bloccato','Accesso bloccato senza eccezioni');
      INSERT INTO access_rights (code, label, description) VALUES
          (2,'Utenti libro parlato','Accesso riservato agli utenti del servizio Libro parlato');
      UPDATE d_objects SET access_right_id=2 WHERE filename ~ '^libroparlato/';
      UPDATE d_objects SET access_right_id=0 WHERE filename ~ '^mp3clips/';
      SQL

  end
  def down
    remove_column :d_objects, :access_right_id
    drop_table :access_rights
  end
end
