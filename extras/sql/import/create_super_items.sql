SET SEARCH_PATH TO import;
set standard_conforming_strings to false;
set backslash_quote to 'safe_encoding';

select now() as "Inizio creazione tabella import.super_items";

drop table if exists super_items CASCADE;
create table super_items as select * from view_super_items;
alter table super_items add column id serial primary key;
alter table super_items add column topogr_id integer;
create unique index super_items_topogr_idx on super_items (topogr_id);
select now() as "Fine creazione tabella import.super_items";

/* Esempio di aggiornamento location_id da verificare:
 
UPDATE import.collocazioni cl set location_id=54 FROM import.item ci
   WHERE cl.item_id=ci.item_id
     and ( cl.primo_i between 607 and 639 ) and ci.home_library_id=2 and cl.location_id is null;
UPDATE import.collocazioni cl set location_id=54 FROM import.super_items ci
   WHERE cl.topogr_id=ci.topogr_id
     and ( cl.primo_i between 607 and 639 ) and ci.home_library_id=2 and cl.location_id is null;
*/

/*
Inizio creazione tabella import.super_items | 2024-05-12 19:57:17.17669+02
DROP TABLE
SELECT 1728060
  Fine creazione tabella import.super_items | 2024-05-12 20:01:56.771747+02
*/

