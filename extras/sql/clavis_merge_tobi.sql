BEGIN;
DROP TABLE da_inserire_in_clavis;
COMMIT;

DELETE FROM clavis.item WHERE home_library_id=-1;

CREATE TABLE da_inserire_in_clavis AS
  SELECT t.owner_library_id,t.inventory_serie_id,t.inventory_number,
   t.collocazione,t.titolo,login,
   t.ctime as date_created,t.mtime as date_updated,
   t.note,t.note_interne,
   t.id as source_id
   FROM topografico_non_in_clavis t LEFT JOIN clavis.item
   ci USING(owner_library_id,inventory_number,inventory_serie_id) WHERE ci IS NULL AND NOT t.deleted;

SELECT setval('clavis.item_item_id_seq', (SELECT MAX(item_id) FROM clavis.item)+1);
INSERT INTO clavis.item(
   manifestation_id,home_library_id,owner_library_id,inventory_serie_id,inventory_number,
   collocation,title,item_media,issue_number,item_icon,
   date_created,date_updated,custom_field1,custom_field2,custom_field3
   )
   (select
     0,-1,owner_library_id,inventory_serie_id,inventory_number,collocazione,
     CASE WHEN note_interne NOTNULL THEN
        titolo || ' [nota interna tobi: ' || note_interne || ']'
     ELSE
	titolo
     END as titolo,
     'F',0,'',
     date_created,date_updated,note,'Inserito in ToBi da ' || login,source_id
    from da_inserire_in_clavis
   );

CREATE UNIQUE INDEX item_custom_field3 ON clavis.item(custom_field3) WHERE home_library_id=-1 AND custom_field3 notnull;

BEGIN;
DROP TABLE clavis.collocazioni;
COMMIT;

CREATE TABLE clavis.collocazioni AS
  SELECT item_id, public.compact_collocation("section",collocation,specification,
    sequence1,sequence2) AS collocazione, ''::text as sort_text
   FROM clavis.item;

DELETE FROM clavis.collocazioni WHERE collocazione='';
UPDATE clavis.collocazioni SET sort_text = espandi_collocazione(collocazione);

ALTER TABLE clavis.collocazioni add primary key(item_id);
CREATE INDEX collocazioni_idx ON clavis.collocazioni(collocazione);
CREATE INDEX collocazioni_sort_text_idx ON clavis.collocazioni(sort_text);

\i extras/sql/trigger_clavis_item.sql
