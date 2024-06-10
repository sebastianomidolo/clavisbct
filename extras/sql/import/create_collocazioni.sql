-- Questa sostituirà extras/sql/clavis_merge_tobi.sql


SET SEARCH_PATH TO import;

set standard_conforming_strings to false;
set backslash_quote to 'safe_encoding';

select now() as "Inizio creazione tabella import.collocazioni";
drop table if exists collocazioni cascade;

CREATE TABLE collocazioni AS
  SELECT item_id, format_collocation(item) as colloc_stringa
FROM item;

-- Ora aggiungo le collocazioni provenienti dal topografico
ALTER TABLE collocazioni ADD COLUMN topogr_id integer;
with t1 AS
(
  SELECT t.collocazione,t.id
   FROM public.topografico_non_in_clavis t LEFT JOIN item
   ci USING(home_library_id,inventory_number,inventory_serie_id) WHERE ci IS NULL AND t.deleted=false
UNION
  SELECT t.collocazione,t.id
   FROM public.topografico_non_in_clavis t JOIN item
   ci USING(home_library_id,inventory_number,inventory_serie_id) WHERE ci.collocation!=t.collocazione
   AND t.deleted=false
)
insert into collocazioni(topogr_id,colloc_stringa) (select id,collocazione from t1);


select now() as "OK creazione tabella, inizio trattamenti preliminari";
-- Trattamenti preliminari delle collocazioni
UPDATE collocazioni SET colloc_stringa = rtrim(regexp_replace(colloc_stringa, E'\\.+', '.', 'g'),'.');
select now() as "OK trattamenti preliminari";

ALTER TABLE collocazioni
  ADD COLUMN sort_text text,
  ADD COLUMN primo character varying(128),
  ADD COLUMN secondo character varying(128),
  ADD COLUMN terzo character varying(128),
  ADD COLUMN quarto character varying(128),
  ADD COLUMN primo_i integer,
  ADD COLUMN secondo_i integer,
  ADD COLUMN terzo_i integer,
  ADD COLUMN quarto_i integer,
  ADD COLUMN location_id integer,
  ADD COLUMN numero_elementi integer;

create unique index if not exists collocazioni_item_id_ndx on collocazioni (item_id);
create unique index if not exists collocazioni_topogr_id_ndx on collocazioni (topogr_id);

-- Aggiungere poi constraint location_id integer references public.locations(id) on update cascade on delete set null,
select now() as "Divisione elementi colloc_stringa per items da Clavis";
with t1 as
(
 select item_id,regexp_split_to_array(colloc_stringa, E'\\.|/') as a
  from collocazioni where item_id is not null
)
update collocazioni c set
   primo   = substr(t1.a[1],1,9),
   secondo = substr(t1.a[2],1,9),
   terzo   = substr(t1.a[3],1,9),
   quarto  = substr(t1.a[4],1,9),
   numero_elementi = ARRAY_LENGTH(a,1)
 from t1 where c.item_id=t1.item_id;

select now() as "Divisione elementi colloc_stringa per esemplari da topografico";
with t1 as
(
 select topogr_id,regexp_split_to_array(colloc_stringa, E'\\.|/') as a
  from collocazioni where topogr_id is not null
)
update collocazioni c set
   primo   = substr(t1.a[1],1,9),
   secondo = substr(t1.a[2],1,9),
   terzo   = substr(t1.a[3],1,9),
   quarto  = substr(t1.a[4],1,9),
   numero_elementi = ARRAY_LENGTH(a,1)
 from t1 where c.topogr_id=t1.topogr_id;

select now() as "Aggiornamento elementi numerici";
update collocazioni set primo_i = primo::integer where primo_i is null and primo ~ E'^\\d+$';
update collocazioni set secondo_i = secondo::integer where secondo_i is null and secondo ~ E'^\\d+$';
update collocazioni set terzo_i = terzo::integer where terzo_i is null and terzo ~ E'^\\d+$';
update collocazioni set quarto_i = quarto::integer where quarto_i is null and quarto ~ E'^\\d+$';

select now() as "Aggiornamento sort_key";
UPDATE collocazioni SET sort_text =
  CONCAT_WS('.',
     lpad(primo,   10, '0'),
     lpad(secondo, 10, '0'),
     lpad(terzo,   10, '0'),
     lpad(quarto,  10, '0')
  )
;

select now() as "OK creazione tabella import.collocazioni";

create index if not exists collocazioni_idx on collocazioni(colloc_stringa);
create index if not exists collocazioni_sort_text_idx on collocazioni(sort_text);
create index if not exists collocazioni_location_id_ndx on collocazioni(location_id);
create index if not exists collocazioni_primo_ndx on collocazioni (primo);
create index if not exists collocazioni_secondo_ndx on collocazioni (secondo);

