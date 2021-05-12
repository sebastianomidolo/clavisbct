class SpUser < ActiveRecord::Migration
  def up
    execute <<-SQL
      CREATE TABLE sp.sp_users (
        bibliography_id INTEGER NOT NULL REFERENCES sp.sp_bibliographies ON UPDATE CASCADE,
        user_id INTEGER NOT NULL REFERENCES public.users ON UPDATE CASCADE);
      CREATE UNIQUE INDEX sp_users_idx on sp.sp_users(bibliography_id,user_id);
    SQL
  end

  def down
    execute "DROP TABLE sp.sp_users;"
  end
end
