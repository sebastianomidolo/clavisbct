
BEGIN;DROP VIEW view_prestiti;COMMIT;

CREATE VIEW view_prestiti AS
SELECT l.patron_id, clavis.collocazione(ci.section, ci.collocation, ci.specification, 
    ci.sequence1, ci.sequence2) as collocazione, substr(trim(ci.title),1,22) as title,
    ci.section, ci.collocation, ci.specification, 
    ci.sequence1, ci.sequence2,
    ci.owner_library_id, l.loan_date_begin::date,
    l.loan_date_end::date, l.destination_name,
    ci.item_id,ci.manifestation_id
  FROM clavis.loan l join clavis.item ci using(item_id);


SELECT collocazione,title,espandi_collocazione(collocazione)
from view_prestiti
  WHERE
  owner_library_id=2
      and loan_date_begin='2013-02-14'
   and loan_date_end isnull
  order by section, espandi_collocazione(collocazione), specification, sequence1, sequence2
;

