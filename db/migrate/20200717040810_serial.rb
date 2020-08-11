class Serial < ActiveRecord::Migration
  def up
    execute <<-SQL
      create table serial_lists (id serial primary key, title varchar(128) not null, year char(4),
                               note varchar(255), locked boolean default false,
			       import_file varchar(128),
                               libraries_file varchar(128));
      create table serial_libraries (serial_list_id integer NOT NULL REFERENCES serial_lists on update cascade,
                                     clavis_library_id integer not null, sigla char(1),
                                     updated_by integer REFERENCES users ON UPDATE CASCADE ON DELETE SET NULL,
                                     date_updated timestamp, nickname varchar(64));
      create table serial_titles (id serial primary key,
               serial_list_id integer NOT NULL REFERENCES serial_lists on update cascade,
               manifestation_id integer, title varchar(255),
               sortkey varchar(255),
               prezzo_stimato money,
	       sospeso boolean default false,
	       estero boolean default NULL,
	       note text, updated_by integer REFERENCES users ON UPDATE CASCADE ON DELETE SET NULL,
               date_updated timestamp, textdata text);
      create table serial_subscriptions (serial_title_id integer NOT NULL REFERENCES serial_titles ON UPDATE CASCADE,
                  library_id integer, note varchar(255), numero_copie integer not null default 1,
                  updated_by integer REFERENCES users ON UPDATE CASCADE ON DELETE SET NULL,
                   date_updated timestamp, tipo_fornitura char(1) not null, prezzo money, info_fattura varchar(255));
      create table serial_users (serial_list_id integer references serial_lists on update cascade on delete cascade,
                                 user_id        integer references users on update cascade on delete cascade);
      create unique index serial_titles_ndx on serial_titles (title,serial_list_id);
      create unique index serial_lists_ndx on serial_lists (title);
      create unique index serial_libraries_ndx on serial_libraries (serial_list_id,clavis_library_id);
      alter table serial_subscriptions add primary key (serial_title_id,library_id);
    SQL

  end

  def down
    drop_table :serial_users
    drop_table :serial_subscriptions
    drop_table :serial_titles
    drop_table :serial_libraries
    drop_table :serial_lists
  end
end
