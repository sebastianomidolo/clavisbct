class BioIconNamespaces < ActiveRecord::Migration
  def up
    create_table :bio_icon_namespaces, id:false do |t|
      t.string :label, :limit=>8
      t.string :title, :limit=>32
      t.string :descr, :limit=>128
    end
    create_table :bio_icon_namespaces_users, :id => false do |t|
      t.string :label
      t.integer :user_id
    end

    execute <<-SQL
      ALTER TABLE bio_icon_namespaces ADD PRIMARY KEY(label);
      ALTER TABLE bio_icon_namespaces_users ADD CONSTRAINT label_fkey
        FOREIGN KEY(label) REFERENCES bio_icon_namespaces
         ON UPDATE CASCADE ON DELETE CASCADE;
      ALTER TABLE bio_icon_namespaces_users ADD CONSTRAINT user_id_fkey
        FOREIGN KEY(user_id) REFERENCES users
         ON UPDATE CASCADE ON DELETE CASCADE;
      ALTER TABLE bio_icon_namespaces_users ALTER COLUMN label SET NOT NULL;
      ALTER TABLE bio_icon_namespaces_users ALTER COLUMN user_id SET NOT NULL;
      INSERT INTO bio_icon_namespaces (label, title) VALUES('bioico','Repertorio bio-iconografico'),
                  ('catarte','Catalogo Arte'),
                  ('cattor','Catalogo Torino');
      CREATE UNIQUE INDEX bio_icon_namespaces_users_idx ON bio_icon_namespaces_users(label,user_id);
    SQL

  end

  def down
    drop_table :bio_icon_namespaces_users
    drop_table :bio_icon_namespaces
  end
end
