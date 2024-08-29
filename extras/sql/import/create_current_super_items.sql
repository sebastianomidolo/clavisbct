SET SEARCH_PATH TO import;
set standard_conforming_strings to false;
set backslash_quote to 'safe_encoding';

select now() as "Creazione tabella public.current_super_items";

drop table if exists public.current_super_items CASCADE;
create table public.current_super_items as select * from view_super_items;
alter table public.current_super_items add column id serial primary key;
alter table public.current_super_items add column topogr_id integer;
create unique index current_super_items_topogr_idx on public.current_super_items (topogr_id);
select now() as "OK tabella public.current_super_items";

create index current_super_items_dw3_idx on public.current_super_items(dw3);


-- Indici
create index current_super_items_item_id_idx on public.current_super_items (item_id);
create index current_super_items_home_library_id_idx on public.current_super_items (home_library_id);
create index current_super_items_genere_idx on public.current_super_items (genere);
create index current_super_items_pubblico_idx on public.current_super_items (pubblico);
create index current_super_items_item_status_idx on public.current_super_items (item_status);
