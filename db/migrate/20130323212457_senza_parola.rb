class SenzaParola < ActiveRecord::Migration
  def up
    execute <<-SQL
      CREATE SCHEMA sp;
      CREATE TABLE sp.sp_bibliographies (
        id varchar(64) PRIMARY KEY,
        created_at timestamp default now(),
        updated_at timestamp,
        title varchar(512) not null,
        subtitle varchar(512),
        description text,
        html_description text,
        comment varchar(512),
        status char(1)
      );
      CREATE TABLE sp.sp_sections (
        bibliography_id varchar(64) NOT NULL REFERENCES sp.sp_bibliographies ON UPDATE CASCADE ON DELETE CASCADE,
        number integer NOT NULL,
        parent integer NOT NULL,
        title varchar(128) NOT NULL,
        description text,
        sortkey varchar(128),
        status char(1),
        PRIMARY KEY(bibliography_id,number)
      );
      CREATE TABLE sp.sp_items (
        id SERIAL PRIMARY KEY,
        item_id varchar(64),
        -- bibliography_id varchar(64) NOT NULL REFERENCES sp.sp_bibliographies ON UPDATE CASCADE ON DELETE CASCADE,
        bibliography_id varchar(64),
        created_at timestamp,
        updated_at timestamp,
        bibdescr text,
        sortkey varchar(512),
        note text,
        mainentry varchar(512),
        collciv varchar(512),
        colldec varchar(512),
        sigle   varchar(512),
        section_number integer,
        sbn_bid varchar(512)
      );
    SQL
  end

  def down
    execute <<-SQL
      DROP SCHEMA sp CASCADE;
    SQL
  end

end
