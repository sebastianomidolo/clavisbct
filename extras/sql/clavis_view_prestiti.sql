
-- BEGIN;DROP VIEW clavis.view_prestiti;COMMIT;

CREATE OR REPLACE VIEW clavis.view_prestiti AS
SELECT l.patron_id, clavis.collocazione(ci.section, ci.collocation, ci.specification, 
    ci.sequence1, ci.sequence2) as collocazione, substr(trim(ci.title),1,80) as title,
    ci.section, ci.collocation, ci.specification, 
    ci.sequence1, ci.sequence2,
    ci.owner_library_id, l.loan_date_begin::date,
    l.loan_date_end::date, l.destination_name,
    ci.item_id,ci.manifestation_id,
    ci.item_media,
    p.barcode,ci.barcode as item_barcode,
    ci.inventory_serie_id || '-' || ci.inventory_number as inventario
  FROM clavis.loan l join clavis.item ci using(item_id)
       join clavis.patron p on(p.patron_id=l.patron_id);

/*
SELECT collocazione,title,espandi_collocazione(collocazione)
from clavis.view_prestiti
  WHERE
  owner_library_id=2
    and loan_date_begin='2013-02-20'
   and loan_date_end isnull
  order by section, espandi_collocazione(collocazione),
   specification, sequence1, sequence2;
*/

