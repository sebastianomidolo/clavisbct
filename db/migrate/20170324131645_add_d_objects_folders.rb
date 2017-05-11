class AddDObjectsFolders < ActiveRecord::Migration
  def up
    execute(%Q{
     CREATE TABLE d_objects_folders AS
      select distinct get_dirname(filename) as name, array_agg(id) as ids
        from d_objects group by get_dirname(filename);

     alter table d_objects_folders add column id serial primary key;

     create table d_objects_d_objects_folders AS
      select id as d_objects_folder_id,unnest(ids) as d_object_id
       from d_objects_folders;
 
     alter table d_objects_folders drop column ids;
     CREATE UNIQUE INDEX d_objects_folders_idx_name ON d_objects_folders(name);

     ALTER TABLE d_objects_folders ALTER COLUMN name SET NOT NULL;

     ALTER TABLE d_objects_d_objects_folders ALTER COLUMN d_objects_folder_id SET NOT NULL;
     ALTER TABLE d_objects_d_objects_folders ALTER COLUMN d_object_id SET NOT NULL;

     ALTER TABLE d_objects_d_objects_folders
       ADD CONSTRAINT d_objects_folder_id_fk FOREIGN KEY (d_objects_folder_id)
        REFERENCES d_objects_folders(id) ON UPDATE CASCADE ON DELETE CASCADE;

     ALTER TABLE d_objects_d_objects_folders
       ADD CONSTRAINT d_object_id_fk FOREIGN KEY (d_object_id)
       REFERENCES d_objects ON UPDATE CASCADE ON DELETE CASCADE;
    })
  end

  def down
    execute(%Q{
      drop table d_objects_d_objects_folders;
      drop table d_objects_folders ;
    })
  end
end
