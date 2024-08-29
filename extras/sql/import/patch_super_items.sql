SET SEARCH_PATH TO import;

-- Inseriamo qui le updates per la tabella super_items, creata da create_super_items.sql

-- Primi tre caratteri Dewey classif
--alter table super_items add column dw3 char(3);
--update super_items set dw3=substr(colloc_stringa,1,3) where substr(colloc_stringa,1,3) ~ E'^\\d{3}$';
--update super_items si
--  set dw3=  CASE
--   when si.class_code is not null then substr(si.class_code,1,3)
--   when si.class_code is null and si.up_class_code is not null then substr(si.up_class_code,1,3)
--   else 'NA'
--  END
-- where si.home_library_id=2;


create index super_items_dw3_idx on super_items(dw3);


-- Indici
create index super_items_item_id_idx on super_items (item_id);
create index super_items_home_library_id_idx on super_items (home_library_id);
create index super_items_genere_idx on super_items (genere);
create index super_items_pubblico_idx on super_items (pubblico);
create index super_items_item_status_idx on super_items (item_status);
create index super_items_colloc_stringa_idx on super_items (colloc_stringa);

-- aggiunto 7 giugno 2024
create index super_items_libsernum_ndx on super_items (home_library_id,inventory_number,inventory_serie_id);



