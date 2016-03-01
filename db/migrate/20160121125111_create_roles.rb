class CreateRoles < ActiveRecord::Migration

  def up
    create_table :roles do |t|
      t.string :name
    end
    create_table :roles_users, :id => false do |t|
      t.references :role, :user
    end

    execute <<-SQL
      ALTER TABLE roles_users ADD CONSTRAINT role_id_fkey
        FOREIGN KEY(role_id) REFERENCES roles
         ON UPDATE CASCADE ON DELETE CASCADE;
      ALTER TABLE roles_users ADD CONSTRAINT user_id_fkey
        FOREIGN KEY(user_id) REFERENCES users
         ON UPDATE CASCADE ON DELETE CASCADE;

      CREATE UNIQUE INDEX roles_names_idx ON roles(name);

      CREATE UNIQUE INDEX roles_users_idx ON roles_users(role_id,user_id);

      ALTER TABLE roles ALTER COLUMN name SET NOT NULL;

    SQL

  end
 
  def down
    drop_table :roles_users
    drop_table :roles
  end

end
