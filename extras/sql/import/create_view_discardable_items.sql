
SET SEARCH_PATH TO import;

set standard_conforming_strings to false;
set backslash_quote to 'safe_encoding';

DROP VIEW IF EXISTS view_discardable_items;
CREATE OR REPLACE VIEW view_discardable_items as

SELECT dr.id,item_id,home_library_id,home_library,dr.descrizione,dr.classe_from || '-' || dr.classe_to as classe,
       dr.edition_age, dr.anni_da_ultimo_prestito,dr.pubblico,si.dw3,
  case
    when
    (
       (
     si.ultimo_prestito is null or
      (date_part('year',now()) - date_part('year', si.ultimo_prestito)) > dr.anni_da_ultimo_prestito
       )
     and (date_part('year',now())-si.print_year) > dr.edition_age
    )
    then true
    else false
  end as discardable

from public.current_super_items si join public.discard_rules dr
   on (si.dw3 between dr.classe_from and dr.classe_to
--        and si.genere = dr.genere
       and si.pubblico = dr.pubblico)
   where si.home_library is not null;
   



