-- set standard_conforming_strings to false;
-- set backslash_quote to 'safe_encoding';
-- set escape_string_warning to false;

SET SEARCH_PATH TO import;
DROP TABLE if exists da_inserire_in_clavis;
DROP TABLE if exists excolloc;

-- DELETE FROM item WHERE owner_library_id=-1;
-- UPDATE topografico_non_in_clavis SET deleted=false WHERE deleted IS NULL;

CREATE TABLE da_inserire_in_clavis AS
  SELECT t.home_library_id,t.inventory_serie_id,t.inventory_number,
   t.collocazione,t.titolo,login,
   t.ctime as date_created,t.mtime as date_updated,
   t.note_interne,
   t.id as source_id
   FROM public.topografico_non_in_clavis t LEFT JOIN item
   ci USING(home_library_id,inventory_number,inventory_serie_id) WHERE ci IS NULL AND t.deleted=false
UNION
  SELECT t.home_library_id,t.inventory_serie_id,t.inventory_number,
   t.collocazione,t.titolo,login,
   t.ctime as date_created,t.mtime as date_updated,
   t.note_interne,
   t.id as source_id
   FROM public.topografico_non_in_clavis t JOIN item
   ci USING(home_library_id,inventory_number,inventory_serie_id) WHERE ci.collocation!=t.collocazione
   AND t.deleted=false;

-- Recupero items con custom_field3 contente ex-collocazione,
-- esempio: "ex 60.C.36"
-- custom_field3 può contenere anche collocazioni che iniziano per "BCT." o per "BCT ": entrambi i prefissi verranno comunque eliminati
-- (fino a agosto 2022 veniva accettato solo il prefisso "BCT.")
-- DELETE FROM item WHERE owner_library_id=-3;
CREATE TABLE excolloc AS
  SELECT item_id, trim(substr(custom_field1,3)) AS excollocazione FROM item WHERE custom_field1 ~* '^ex';
UPDATE excolloc SET excollocazione=replace(excollocazione,'BCT.','') WHERE excollocazione ~* '^BCT\\.';
UPDATE excolloc SET excollocazione=replace(excollocazione,'BCT ','') WHERE excollocazione ~ '^BCT ';
UPDATE excolloc SET excollocazione=replace(excollocazione,' ','.') WHERE excollocazione ~ ' ';


SELECT setval('item_item_id_seq', (SELECT MAX(item_id) FROM item)+1000);
INSERT INTO item(
   manifestation_id,home_library_id,owner_library_id,inventory_serie_id,inventory_number,
   collocation,title,item_media,issue_number,item_icon,
   date_created,date_updated,custom_field2,custom_field3
   )
   (select
     0,home_library_id,-1,inventory_serie_id,inventory_number,collocazione,
     CASE WHEN note_interne != '' THEN
        titolo || ' [note: ' || note_interne || ']'
     ELSE
	titolo
     END as titolo,
     'F',0,'',
     date_created,date_updated,'Inserito in ClavisBct (alias ToBi) da ' || login,source_id
    from da_inserire_in_clavis
   );

INSERT INTO item(
   manifestation_id,home_library_id,owner_library_id,inventory_serie_id,inventory_number,
   collocation,title,item_media,issue_number,item_icon,
   date_created,date_updated,custom_field1,
   item_status,loan_status,opac_visible
   )
   (
    select
     manifestation_id,home_library_id,-3,inventory_serie_id,inventory_number*-1,excollocazione,
     '[Nuova collocazione => ' ||
    public.compact_collocation(item."section",item.collocation,item.specification,
         item.sequence1,item.sequence2) || '] ' || title,item_media,issue_number,item_icon,
     date_created,date_updated,item_id,
     item_status,loan_status,opac_visible
   from excolloc join item using(item_id)
   );


CREATE UNIQUE INDEX item_custom_field3 ON item(custom_field3) WHERE owner_library_id=-1 AND custom_field3 notnull;
CREATE UNIQUE INDEX item_custom_field1 ON item(custom_field1) WHERE owner_library_id=-3 AND custom_field1 notnull;

CREATE TABLE collocazioni AS
  SELECT item_id, public.compact_collocation("section",collocation,specification,
    sequence1,sequence2) AS collocazione, ''::text as sort_text
   FROM item;

UPDATE collocazioni
  SET collocazione = trim(regexp_replace(collocazione, '\\(.*',''), '. ')
   WHERE collocazione ~ '\\(';

UPDATE collocazioni SET collocazione = replace(collocazione, ' ','.') WHERE collocazione ~ '^LP';

UPDATE collocazioni SET collocazione=upper(collocazione) WHERE collocazione ~* '^per';
UPDATE collocazioni SET collocazione=replace(collocazione, ' ', '.') WHERE collocazione ~ '^PER';
UPDATE collocazioni SET collocazione=replace(collocazione, '..', '.') WHERE collocazione like 'PER..%';


DELETE FROM collocazioni WHERE collocazione='';
UPDATE collocazioni SET sort_text = public.espandi_collocazione(collocazione);

alter table collocazioni add column location_id integer;
alter table collocazioni add constraint location_id_fkey
    foreign key(location_id) references public.locations(id) on update cascade on delete set null;

alter table collocazioni add column primo character varying(128);
alter table collocazioni add column secondo character varying(128);
alter table collocazioni add column terzo character varying(128);
alter table collocazioni add column primo_i integer;
alter table collocazioni add column secondo_i integer;
alter table collocazioni add column terzo_i integer;

with t1 as
-- (select item_id,collocazione,string_to_array(collocazione, '.') as a
(select item_id,collocazione, regexp_split_to_array(collocazione, '\\.| ') as a

   from collocazioni cc join item ci using(item_id)
    where ci.item_status != 'E')
update collocazioni c set primo = t1.a[1],secondo = t1.a[2],terzo = t1.a[3]
    from t1 where c.item_id=t1.item_id;
update collocazioni set primo_i = primo::integer where primo_i is null and primo ~ '^\\d+$';
update collocazioni set secondo_i = secondo::integer where secondo_i is null and secondo ~ '^\\d+$';
update collocazioni set terzo_i = terzo::integer where terzo_i is null and terzo ~ '^\\d+$';


ALTER TABLE collocazioni add primary key(item_id);
CREATE INDEX collocazioni_idx ON collocazioni(collocazione);
CREATE INDEX collocazioni_sort_text_idx ON collocazioni(sort_text);
CREATE INDEX collocazioni_location_id_ndx ON collocazioni(location_id);
