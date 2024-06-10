SET SEARCH_PATH TO import;
set standard_conforming_strings to false;
set backslash_quote to 'safe_encoding';

select now() as "Inizio creazione tabella import.discardable_items";

drop table if exists discardable_items;

create table discardable_items as select * from view_discardable_items;

create unique index discardable_items_item_id_idx on discardable_items(item_id);


select now() as "Fine creazione tabella import.discardable_items";


