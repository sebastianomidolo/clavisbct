SET SEARCH_PATH TO import;
-- BEGIN;DROP VIEW view_prestiti;COMMIT;

CREATE OR REPLACE VIEW view_prestiti AS
SELECT l.patron_id, collocazione(ci.section, ci.collocation, ci.specification, 
    ci.sequence1, ci.sequence2) as collocazione, substr(trim(ci.title),1,80) as title,
    ci.section, ci.collocation, ci.specification, 
    ci.sequence1, ci.sequence2,
    ci.owner_library_id, ci.home_library_id, l.loan_date_begin::date,
    l.loan_date_end::date, l.destination_name,l.loan_status,
    ci.item_id,ci.manifestation_id,
    ci.item_media,
    p.barcode,ci.barcode as item_barcode,
    ci.inventory_serie_id || '-' || ci.inventory_number as inventario
  FROM loan l join item ci using(item_id)
       join patron p on(p.patron_id=l.patron_id);



CREATE OR REPLACE VIEW view_prestiti2 as
SELECT ci.item_id,cl.loan_id, cl.loan_status, ls.value_label as loan_status_label,
 cl.loan_date_begin, cl.loan_date_end, cl.renew_count,
  extract(days from cl.loan_date_end - cl.loan_date_begin) as giorni
FROM
    loan cl JOIN item ci USING(item_id)
     JOIN lookup_value ls
       ON(cl.loan_status=ls.value_key AND value_class ~ 'LOANSTATUS' AND value_language='it_IT')
WHERE cl.loan_status!='H';

/*
SELECT collocazione,title,espandi_collocazione(collocazione)
from view_prestiti
  WHERE
  owner_library_id=2
    and loan_date_begin='2013-02-20'
   and loan_date_end isnull
  order by section, espandi_collocazione(collocazione),
   specification, sequence1, sequence2;
*/

CREATE OR REPLACE VIEW view_prestiti_sciutti AS
SELECT
 l.loan_id,
 l.loan_status,l.manifestation_id as loan_mid,
 l.item_id,
 l.class_code,
 l.external_library_id,
 item_owner_library_id,item_home_library_id,from_library,to_library,end_library,
 l.loan_date_begin,
 l.loan_date_end,
 l.due_date,
 age(l.loan_date_end,l.loan_date_begin) as durata,
 l.renew_count,
 ci.item_media,
 p.last_seen,
 p.patron_id
 FROM
 loan l
 join item ci using(item_id)
 left join patron p on(l.patron_id=p.patron_id);
 
	  

/*
\o /home/storage/preesistente/static/sara.csv
\copy (SELECT * FROM sara WHERE anno_pubblicazione between 2012 and 2022 ORDER BY anno_pubblicazione) TO stdout csv header
\o
\o /home/storage/preesistente/static/sara_include_non_prestati.csv
\copy (SELECT * FROM sara2 WHERE anno_pubblicazione between 2012 and 2022 ORDER BY anno_pubblicazione) TO stdout csv header
\o

Esempio di query che limita la ricerca alle biblioteche BCT con siglabib (le "nostre"):
select * from tobi_loan l join sara2 s on (s.manifestation_id=l.loan_mid) 
  join sbct_acquisti.library_codes lc on (lc.clavis_library_id=l.item_owner_library_id);

-- eventualmente limitare a: class_code is not null and bib_level='m'

*/
  


/*
 * Comando da dare a mano per estrarre i dati necessari a Fabrizio Sciutti per le statistiche annuali 
 * NOTA: la tobi_loan serve solo per le statistiche di Sciutti, dunque inutile crearla ogni volta, ma sono quando serve:

CREATE TABLE tobi_loan AS
 SELECT * FROM view_prestiti_sciutti
  WHERE loan_date_begin notnull and due_date notnull
 UNION
 SELECT * FROM view_prestiti_sciutti
  WHERE age(loan_date_end,loan_date_begin) > interval '0 seconds'
 UNION
  SELECT * FROM view_prestiti_sciutti
 WHERE loan_date_begin is null;

ALTER TABLE tobi_loan add primary key (loan_id);

CREATE OR REPLACE VIEW view_export_prestiti_sciutti AS
SELECT
loan_id,loan_status,loan_mid,item_id,class_code,external_library_id,item_owner_library_id,
item_home_library_id,from_library,to_library,end_library,loan_date_begin,loan_date_end,due_date,
durata,renew_count,item_media,last_seen,patron_id
 FROM tobi_loan
 WHERE loan_status!='H';


create or replace view sara as
  select
  cm."ISBNISSN" as isbn,
  cm.bib_level,
  p.item_media as formato,
  cm.author as autore,
  cm.title as titolo,
  cm.publisher as editore,
  cm.edition_date as anno_pubblicazione,
  p.class_code as cdd,
  cm.edition_language as lingua,
  count(*) as numero_prestiti,
  manifestation_id
  from view_export_prestiti_sciutti p join manifestation cm  on(manifestation_id=loan_mid)
--  where edition_date between 2012 and 2022
  where item_owner_library_id=2 -- Civica centrale
  group by
  isbn,
  cm.bib_level,
  formato,
  autore,
  titolo,
  editore,
  anno_pubblicazione,
  cdd,
  lingua,
  manifestation_id;

create or replace view sara2 as
  select
  cm."ISBNISSN" as isbn,
  cm.bib_level,
  ci.home_library_id,
  -- array_to_string(array_agg(p.loan_id), ',') as loan_ids,
  lc.label as siglabib,
  cm.author as autore,
  cm.title as titolo,
  cm.publisher as editore,
  cm.edition_date as anno_pubblicazione,
  p.class_code as cdd,
  cm.edition_language as lingua,
  count(p.loan_id) as numero_prestiti,
  manifestation_id
  from 
    manifestation cm
    left join
    view_export_prestiti_sciutti p on(manifestation_id=loan_mid)
    left join sbct_acquisti.library_codes lc on (lc.clavis_library_id=p.item_home_library_id)
    join item ci using(manifestation_id)

--  where edition_date between 2012 and 2022
--   where item_owner_library_id=2 -- Civica centrale
where cm.bib_level='m'
  group by
  isbn,
  bib_level,
  autore,
  titolo,
  editore,
  anno_pubblicazione,
  cdd,
  lingua,
  manifestation_id,
  siglabib,
  ci.home_library_id;


\o /home/storage/preesistente/static/stat/2022_prestiti_bct.csv
\copy (SELECT * FROM view_export_prestiti_sciutti WHERE loan_date_begin BETWEEN '2021-11-01' AND '2021-12-31' ORDER BY loan_id) TO stdout csv header
\o


\o /home/storage/preesistente/static/stat/2021_prestiti_bct.csv
\copy (SELECT * FROM view_export_prestiti_sciutti WHERE loan_date_begin BETWEEN '2020-11-01' AND '2020-12-31' ORDER BY loan_id) TO stdout csv header
\o


\o /home/storage/preesistente/static/stat/2020_prestiti_bct.csv
\copy (SELECT * FROM view_export_prestiti_sciutti WHERE loan_date_begin BETWEEN '2019-11-01' AND '2019-12-31' ORDER BY loan_id) TO stdout csv header
\o

\o /home/storage/preesistente/static/stat/2019_prestiti_bct.csv
\copy (SELECT * FROM view_export_prestiti_sciutti WHERE loan_date_begin BETWEEN '2018-11-01' AND '2018-12-31' ORDER BY loan_id) TO stdout csv header
\o

\o /home/storage/preesistente/static/stat/2018_prestiti_bct.csv
\copy (SELECT * FROM view_export_prestiti_sciutti WHERE loan_date_begin BETWEEN '2017-11-01' AND '2017-12-31' ORDER BY loan_id) TO stdout csv header
\o

\o /home/storage/preesistente/static/stat/2017_prestiti_bct.csv
\copy (SELECT * FROM view_export_prestiti_sciutti WHERE loan_date_begin BETWEEN '2016-11-01' AND '2016-12-31' ORDER BY loan_id) TO stdout csv header
\o

\o /home/storage/preesistente/static/stat/2016_prestiti_bct.csv
\copy (SELECT * FROM view_export_prestiti_sciutti WHERE loan_date_begin BETWEEN '2015-11-01' AND '2015-12-31' ORDER BY loan_id) TO stdout csv header
\o

\o /home/storage/preesistente/static/stat/tobi_loan.csv
\copy (select * from tobi_loan) TO stdout csv header;
\o


\o /home/storage/preesistente/static/stat/esemplari.csv
\copy (select * from item where loan_status notnull) TO stdout csv header;
\o

*/    
