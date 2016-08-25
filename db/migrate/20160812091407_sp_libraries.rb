# Corrispondenza tra le sigle di biblioteche usate in SenzaParola e gli id biblioteche Clavis
class SpLibraries < ActiveRecord::Migration
  def up
    execute %Q{
     CREATE TABLE sp.sp_libraries (
       clavis_library_id integer not null,
       sp_library_code char(1) primary key);
     INSERT INTO sp.sp_libraries (clavis_library_id,sp_library_code) VALUES
        (10, 'A'),
        (11, 'B'),
        (13, 'D'),
        (14, 'E'),
        (15, 'F'),
        (16, 'H'),
        (17, 'I'),
        (8,  'J'),
        (18, 'L'),
        (19, 'M'),
        (20, 'N'),
        (2,  'Q'),
        (24, 'S'),
        (25, 'T'),
        (496,'U'),
        (27, 'V'),
        (3,  'W'),
        (29, 'Z');
    }
  end

  def down
    execute %Q{
       DROP TABLE sp.sp_libraries;
    }
  end
end
