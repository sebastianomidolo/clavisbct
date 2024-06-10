SET SEARCH_PATH TO import;
set standard_conforming_strings to false;
set backslash_quote to 'safe_encoding';

select now() as "Inserimento in super_items da topografico";
delete from super_items where topogr_id is not null;
select setval('super_items_id_seq', (select max(id) from super_items));

with tt as
(
  SELECT t.home_library_id,t.inventory_serie_id,t.inventory_number,
   t.collocazione as colloc_stringa,t.titolo as title,t.login,
   t.ctime as date_created,t.mtime as date_updated,
   t.note_interne,
   t1.topogr_id
   FROM collocazioni as t1 join public.topografico_non_in_clavis t on (t.id=t1.topogr_id)
   LEFT JOIN super_items ci USING(home_library_id,inventory_number,inventory_serie_id)
   WHERE t1.topogr_id is not null AND ci IS NULL AND t.deleted=false
UNION
  SELECT t.home_library_id,t.inventory_serie_id,t.inventory_number,
   t.collocazione as colloc_stringa,t.titolo as title,t.login,
   t.ctime as date_created,t.mtime as date_updated,
   t.note_interne,
   t1.topogr_id
   FROM collocazioni as t1 join public.topografico_non_in_clavis t on (t.id=t1.topogr_id) JOIN super_items
   ci USING(home_library_id,inventory_number,inventory_serie_id)
   WHERE t1.topogr_id is not null AND ci.colloc_stringa!=t.collocazione AND t.deleted=false
 )
insert into super_items
 (
   topogr_id,title,home_library_id,inventory_serie_id,inventory_number,colloc_stringa,item_media,item_status,
     date_created
 )
 (select
   topogr_id,
     CASE WHEN note_interne != '' THEN
        title || ' [note: ' || note_interne || ']'
     ELSE
	title
     END as title,
   home_library_id,inventory_serie_id,inventory_number,colloc_stringa, 'F', 'F', date_created
 from tt)
 on conflict(topogr_id) do nothing;


/* vecchio codice
with t1 AS
(
  SELECT t.home_library_id,t.inventory_serie_id,t.inventory_number,
   t.collocazione,t.titolo,
   t.ctime as date_created,t.mtime as date_updated,
   t.note_interne,
   t.id as topogr_id
   FROM public.topografico_non_in_clavis t LEFT JOIN item
   ci USING(home_library_id,inventory_number,inventory_serie_id) WHERE ci IS NULL AND t.deleted=false
UNION
  SELECT t.home_library_id,t.inventory_serie_id,t.inventory_number,
   t.collocazione,t.titolo,
   t.ctime as date_created,t.mtime as date_updated,
   t.note_interne,
   t.id as topogr_id
   FROM public.topografico_non_in_clavis t JOIN item
   ci USING(home_library_id,inventory_number,inventory_serie_id) WHERE ci.collocation!=t.collocazione
   AND t.deleted=false
)
INSERT INTO super_items(
   manifestation_id,home_library_id,owner_library_id,inventory_serie_id,inventory_number,
   colloc_stringa,title,item_media,item_status,
   date_created,topogr_id
   )
   (select
     NULL, home_library_id, -1, inventory_serie_id, inventory_number, collocazione,
     CASE WHEN note_interne != '' THEN
        titolo || ' [note: ' || note_interne || ']'
     ELSE
	titolo
     END as titolo,
     'F', 'F', date_created, topogr_id
    from t1
   );
*/


