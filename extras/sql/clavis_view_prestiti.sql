
-- BEGIN;DROP VIEW clavis.view_prestiti;COMMIT;

CREATE OR REPLACE VIEW clavis.view_prestiti AS
SELECT l.patron_id, clavis.collocazione(ci.section, ci.collocation, ci.specification, 
    ci.sequence1, ci.sequence2) as collocazione, substr(trim(ci.title),1,80) as title,
    ci.section, ci.collocation, ci.specification, 
    ci.sequence1, ci.sequence2,
    ci.owner_library_id, ci.home_library_id, l.loan_date_begin::date,
    l.loan_date_end::date, l.destination_name,l.loan_status,
    ci.item_id,ci.manifestation_id,
    ci.item_media,
    p.barcode,ci.barcode as item_barcode,
    ci.inventory_serie_id || '-' || ci.inventory_number as inventario
  FROM clavis.loan l join clavis.item ci using(item_id)
       join clavis.patron p on(p.patron_id=l.patron_id);



CREATE OR REPLACE VIEW clavis.view_prestiti2 as
SELECT ci.item_id,cl.loan_id, cl.loan_status, ls.value_label as loan_status_label,
 cl.loan_date_begin, cl.loan_date_end, cl.renew_count,
  extract(days from cl.loan_date_end - cl.loan_date_begin) as giorni
FROM
    clavis.loan cl JOIN clavis.item ci USING(item_id)
     JOIN clavis.lookup_value ls
       ON(cl.loan_status=ls.value_key AND value_class ~ 'LOANSTATUS' AND value_language='it_IT')
WHERE cl.loan_status!='H';

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

CREATE OR REPLACE VIEW clavis.view_prestiti_sciutti AS
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
 clavis.loan l
 join clavis.item ci using(item_id)
 left join clavis.patron p on(l.patron_id=p.patron_id);
 
	  
CREATE TABLE clavis.tobi_loan AS
 SELECT * FROM clavis.view_prestiti_sciutti
  WHERE loan_date_begin notnull and due_date notnull
 UNION
 SELECT * FROM clavis.view_prestiti_sciutti
  WHERE age(loan_date_end,loan_date_begin) > interval '0 seconds'
 UNION
  SELECT * FROM clavis.view_prestiti_sciutti
 WHERE loan_date_begin is null;

ALTER TABLE clavis.tobi_loan add primary key (loan_id);


CREATE OR REPLACE VIEW clavis.view_export_prestiti_sciutti AS
SELECT
loan_id,loan_status,loan_mid,item_id,class_code,external_library_id,item_owner_library_id,
item_home_library_id,from_library,to_library,end_library,loan_date_begin,loan_date_end,due_date,
durata,renew_count,item_media,last_seen,patron_id
 FROM clavis.tobi_loan
 WHERE loan_status!='H';


/*
 * Comando da dare a mano per estrarre i dati necessari a Fabrizio Sciutti per le statistiche annuali 


\o /home/storage/preesistente/static/stat/2020_prestiti_bct.csv
\copy (SELECT * FROM clavis.view_export_prestiti_sciutti WHERE loan_date_begin BETWEEN '2019-11-01' AND '2019-12-31' ORDER BY loan_id) TO stdout csv header
\o

\o /home/storage/preesistente/static/stat/2019_prestiti_bct.csv
\copy (SELECT * FROM clavis.view_export_prestiti_sciutti WHERE loan_date_begin BETWEEN '2018-11-01' AND '2018-12-31' ORDER BY loan_id) TO stdout csv header
\o

\o /home/storage/preesistente/static/stat/2018_prestiti_bct.csv
\copy (SELECT * FROM clavis.view_export_prestiti_sciutti WHERE loan_date_begin BETWEEN '2017-11-01' AND '2017-12-31' ORDER BY loan_id) TO stdout csv header
\o

\o /home/storage/preesistente/static/stat/2017_prestiti_bct.csv
\copy (SELECT * FROM clavis.view_export_prestiti_sciutti WHERE loan_date_begin BETWEEN '2016-11-01' AND '2016-12-31' ORDER BY loan_id) TO stdout csv header
\o

\o /home/storage/preesistente/static/stat/2016_prestiti_bct.csv
\copy (SELECT * FROM clavis.view_export_prestiti_sciutti WHERE loan_date_begin BETWEEN '2015-11-01' AND '2015-12-31' ORDER BY loan_id) TO stdout csv header
\o

\o /home/storage/preesistente/static/stat/tobi_loan.csv
\copy (select * from clavis.tobi_loan) TO stdout csv header;
\o


\o /home/storage/preesistente/static/stat/esemplari.csv
\copy (select * from clavis.item where loan_status notnull) TO stdout csv header;
\o

*/    
