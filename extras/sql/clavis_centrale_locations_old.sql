set standard_conforming_strings to false;
set backslash_quote to 'safe_encoding';
set escape_string_warning to false;

drop table if exists clavis.centrale_locations;

--    where (ci.home_library_id=2 and ci.item_status IN ('F','G','S'))

create table clavis.centrale_locations as
select item_id,collocazione from clavis.collocazioni cc
  join clavis.item ci using(item_id)
    where (ci.home_library_id=2 and ci.item_status NOT IN ('A','L','M'))
     OR (ci.home_library_id=2 and ci.owner_library_id=-1);

delete from clavis.centrale_locations where item_id in
  (select item_id from clavis.item where owner_library_id not in
    (select library_id from clavis.library where library_internal = '1')
      and owner_library_id not in (-1,-3));


alter table clavis.centrale_locations add column piano varchar(24);
alter table clavis.centrale_locations add column primo_elemento varchar(128);

update clavis.centrale_locations set collocazione=replace(collocazione,'A.A.','AA.') where collocazione ~ '^A\.A\.';
update clavis.centrale_locations set collocazione=replace(collocazione,'S.L.','SL.') where collocazione ~ '^S\.L\.';
update clavis.centrale_locations set collocazione=replace(collocazione,'Archivio.Bosio.','ArchivioBosio.') where collocazione ~ '^Archivio\.Bosio\.';
update clavis.centrale_locations set collocazione=replace(collocazione,'Libr.Gioberti.','LibrGioberti.') where collocazione ~ '^Libr\.Gioberti\.';
update clavis.centrale_locations set collocazione=replace(collocazione,'Sez.Gioberti.','SezGioberti.') where collocazione ~ '^Sez\.Gioberti\.';
update clavis.centrale_locations set collocazione=replace(collocazione,'..','.') where collocazione like '%..%';
update clavis.centrale_locations set collocazione=replace(collocazione,' .','.') where collocazione like '% .%';

update clavis.centrale_locations set collocazione = replace(collocazione, 'PG ', 'PG.') where collocazione like 'PG %';
update clavis.centrale_locations set primo_elemento='PERD' where collocazione ~ '^PER\.D';
update clavis.centrale_locations set primo_elemento='PERD' where collocazione ~* '^PERD';

--update clavis.centrale_locations set primo_elemento = substr(split_part(collocazione,'.',1),1,6);
update clavis.centrale_locations set primo_elemento = substr(split_part(collocazione,'.',1),1,128);

alter table clavis.centrale_locations add column secondo_elemento varchar(128);
-- update clavis.centrale_locations set secondo_elemento = substr(split_part(collocazione,'.',2),1,4);
update clavis.centrale_locations set secondo_elemento = substr(split_part(collocazione,'.',2),1,128);
update clavis.centrale_locations set secondo_elemento=trim(secondo_elemento) where secondo_elemento like ' %';

update clavis.centrale_locations set primo_elemento='PER???' where primo_elemento = 'PER'
   and (secondo_elemento ~ '\\D' or secondo_elemento ~ '-');

alter table clavis.centrale_locations add column terzo_elemento varchar(128);
update clavis.centrale_locations set terzo_elemento = substr(split_part(collocazione,'.',3),1,128);

with numeri as
  (select item_id,regexp_matches(collocazione, '\\d+') as num
     from clavis.centrale_locations where collocazione ~ '^P\.G\. ?')
 update clavis.centrale_locations as y
     set primo_elemento='PG',
         secondo_elemento=num[1]::integer,
	 terzo_elemento=NULL
  from numeri where numeri.item_id=y.item_id;

create index clavis_centra_locations_item_id_idx on clavis.centrale_locations(item_id);
create index clavis_centra_locations_piano_idx on clavis.centrale_locations(piano);
create index clavis_centra_locations_primo_elemento_idx on clavis.centrale_locations(primo_elemento);

alter table clavis.centrale_locations add column scaffale integer;

update clavis.centrale_locations set scaffale=primo_elemento::integer where scaffale is null and primo_elemento ~ '^\\d+$';

alter table clavis.centrale_locations add column catena integer;
update clavis.centrale_locations set terzo_elemento = trim(terzo_elemento) where terzo_elemento notnull;
-- update clavis.centrale_locations set catena=terzo_elemento::integer where terzo_elemento ~ '^\\d+$';
update clavis.centrale_locations set catena=split_part(terzo_elemento,'/',1)::integer where split_part(terzo_elemento,'/',1) ~ '^\\d+$';

update clavis.centrale_locations set secondo_elemento = trim(secondo_elemento) where secondo_elemento notnull;
-- update clavis.centrale_locations set catena=secondo_elemento::integer where catena is null and secondo_elemento ~ '^\\d+$';
update clavis.centrale_locations set catena=split_part(secondo_elemento,'/',1)::integer where catena is null and split_part(secondo_elemento,'/',1) ~ '^\\d+$';

-- riepilogo per piano
-- select piano,count(*) from clavis.centrale_locations group by piano order by piano;
