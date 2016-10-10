BEGIN;
CREATE TEMP TABLE excolloc AS
  SELECT item_id, trim(substr(custom_field1,3)) AS excollocazione FROM clavis.item WHERE custom_field1 ~* '^ex';

UPDATE excolloc SET excollocazione=replace(excollocazione,'BCT.','') WHERE excollocazione ~* '^BCT\\.';


SELECT setval('clavis.item_item_id_seq', (SELECT MAX(item_id) FROM clavis.item)+1000);

INSERT INTO clavis.item(
   manifestation_id,home_library_id,owner_library_id,inventory_serie_id,inventory_number,
   collocation,title,item_media,issue_number,item_icon,
   date_created,date_updated,custom_field1,
   item_status,loan_status,opac_visible
   )
   (
    select
     manifestation_id,-3,owner_library_id,inventory_serie_id,inventory_number,excollocazione,
     '[Nuova collocazione => ' ||
    public.compact_collocation(item."section",item.collocation,item.specification,
         item.sequence1,item.sequence2) || '] ' || title,item_media,issue_number,item_icon,
     date_created,date_updated,item_id,
     item_status,loan_status,opac_visible
   from excolloc join clavis.item using(item_id) join clavis.collocazioni using(item_id)
   );

COMMIT;

