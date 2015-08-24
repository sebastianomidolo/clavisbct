BEGIN;
DROP TABLE public.serials_admin_table;
COMMIT;


/* patch temporanea in attesa che venga aggiunta la colonna "data pagamento" */
BEGIN;
ALTER TABLE excel_files_tables.celdes_admin_report_ordini_con_dati_fatturazione
  ADD COLUMN "data pagamento" date;
COMMIT;
BEGIN;
ALTER TABLE excel_files_tables.celdes_admin_report_ordini_con_dati_fatturazione
   ALTER COLUMN "data pagamento" type text using ("data pagamento"::text);
COMMIT;
BEGIN;
UPDATE excel_files_tables.celdes_admin_report_ordini_con_dati_fatturazione set "data pagamento" = NULL
    WHERE "data pagamento"='';
COMMIT;

BEGIN;
ALTER TABLE excel_files_tables.celdes_admin_report_ordini_con_dati_fatturazione_2014
   ALTER COLUMN "data pagamento" type text using ("data pagamento"::text);
COMMIT;
BEGIN;
UPDATE excel_files_tables.celdes_admin_report_ordini_con_dati_fatturazione_2014 set "data pagamento" = NULL
    WHERE "data pagamento"='';
COMMIT;


BEGIN;
ALTER TABLE excel_files_tables.celdes_musicale_admin_report_ordini_con_dati_fatturazione_2014
   ALTER COLUMN "data pagamento" type text using ("data pagamento"::text);
UPDATE excel_files_tables.celdes_musicale_admin_report_ordini_con_dati_fatturazione_2014 set "data pagamento" = NULL
    WHERE "data pagamento"='';
set datestyle TO "DMY";
   ALTER TABLE excel_files_tables.celdes_musicale_admin_report_ordini_con_dati_fatturazione_2014   
   ALTER COLUMN "data pagamento" type date using ("data pagamento"::date);
COMMIT;

BEGIN;
set datestyle TO "DMY";
ALTER TABLE excel_files_tables.celdes_admin_report_ordini_con_dati_fatturazione
   ALTER COLUMN "data pagamento" type date using ("data pagamento"::date);
COMMIT;

-- BEGIN;
-- set datestyle TO "DMY";
-- ALTER TABLE excel_files_tables.celdes_musicale_admin_report_ordini_con_dati_fatturazione
--    ALTER COLUMN "data pagamento" type date using ("data pagamento"::date);
-- COMMIT;
-- BEGIN;
-- UPDATE excel_files_tables.celdes_musicale_admin_report_ordini_con_dati_fatturazione SET numero = NULL WHERE numero='';
-- COMMIT;


BEGIN;
ALTER TABLE excel_files_tables.celdes_musicale_admin_report_ordini_con_dati_fatturazione
  ALTER COLUMN "numero" type integer using ("numero"::integer);
COMMIT;

/*
BEGIN;
UPDATE excel_files_tables.celdes_musicale_admin_report_ordini_con_dati_fatturazione SET "prezzo" = NULL
  WHERE "prezzo"='';
COMMIT;

BEGIN;
ALTER TABLE excel_files_tables.celdes_musicale_admin_report_ordini_con_dati_fatturazione
  ALTER COLUMN "prezzo" type float using ("prezzo"::float);
COMMIT;
*/

/* patch temporanea in attesa che venga aggiunta la colonna "data pagamento" */

BEGIN;
ALTER TABLE excel_files_tables.celdes_musicale_admin_report_ordini_con_dati_fatturazione
  ADD COLUMN "data pagamento" date;
COMMIT;

BEGIN;
UPDATE excel_files_tables.celdes_musicale_admin_report_ordini_con_dati_fatturazione
  SET "data pagamento"=NULL WHERE "data pagamento"='';
COMMIT;


update excel_files_tables.celdes_admin_report_ordini_con_dati_fatturazione set prezzo=NULL where prezzo='';

set datestyle TO "DMY";
CREATE TABLE public.serials_admin_table
AS
select 2015 as anno_fornitura,g.titolo, cc.manifestation_id,b.library_id,f.numero as numero_fattura,
 f."prezzo"::double precision as importo_fattura,"CIG",
 "fattura / nota credito"::char(1) as fattura_o_nota_di_credito,
 "data fattura / nota credito"::date as data_emissione,
 "data pagamento"::date as data_pagamento,
 o.prezzo, o.commissione_sconto, o.totale, o.iva, o."prezzo finale" as prezzo_finale,
 o.numcopie, o.ordnum, o.ordanno, o.ordprogressivo,
 o.abbmesedal || '/' || o.abbannodal || '-' || o.abbmeseal || '/' || o.abbannoal as periodo,
 o.statodettaglio as stato,
 g.formato,NULL as note_interne
  from excel_files_tables.celdes_gest_riepilogo_situazione_ordini g
   left join excel_files_tables.titoli_celdes_clavis cc using(titolo)
   join excel_files_tables.celdes_admin_report_ordini o using(titolo,ordnum,ordprogressivo)
   left join excel_files_tables.celdes_admin_report_ordini_con_dati_fatturazione
    f on(g.titolo=f.titolo and g.destinatario=f.destinatario
----> Nota che la join andrebbe fatta usando o.ordanno,o.ordnum e o.ordprogressivo
----> che però a oggi (giugno 2014) mancano nella tabella f
     and g.abbmesedal=f.abbmesedal
     and g.abbmeseal=f.abbmeseal
     and g.abbannodal=f.abbannodal
     and g.abbannoal=f.abbannoal
     and g.abbvoldal=f.abbvoldal
     and g.abbvolal=f.abbvolal
    )
   join biblioteche_celdes b on(b.label=g.destinatario)

UNION
-- BCT 2014
select 2014 as anno_fornitura,g.titolo, cc.manifestation_id,b.library_id,f.numero as numero_fattura,
 f."totale articolo" as importo_fattura,"CIG",
 "fattura / nota credito"::char(1) as fattura_o_nota_di_credito,
 "data fattura / nota credito"::date as data_emissione,
 "data pagamento"::date as data_pagamento,
 o.prezzo, o.commissione_sconto, o.totale, o.iva, o."prezzo finale" as prezzo_finale,
 o.numcopie, o.ordnum, o.ordanno, o.ordprogressivo,
 o.abbmesedal || '/' || o.abbannodal || '-' || o.abbmeseal || '/' || o.abbannoal as periodo,
 o.statodettaglio as stato,
 g.formato,NULL as note_interne
  from excel_files_tables.celdes_gest_riepilogo_situazione_ordini g
   left join excel_files_tables.titoli_celdes_clavis cc using(titolo)
   join excel_files_tables.celdes_admin_report_ordini o using(titolo,ordnum,ordprogressivo)
   left join excel_files_tables.celdes_admin_report_ordini_con_dati_fatturazione_2014
    f on(g.titolo=f.titolo and g.destinatario=f.destinatario
----> Nota che la join andrebbe fatta usando o.ordanno,o.ordnum e o.ordprogressivo
----> che però a oggi (giugno 2014) mancano nella tabella f
     and g.abbmesedal=f.abbmesedal
     and g.abbmeseal=f.abbmeseal
     and g.abbannodal=f.abbannodal
     and g.abbannoal=f.abbannoal
     and g.abbvoldal=f.abbvoldal
     and g.abbvolal=f.abbvolal
    )
   join biblioteche_celdes b on(b.label=g.destinatario)

UNION
-- musicale
select 2015 as anno_fornitura,o.titolo, cc.manifestation_id, 3 as library_id, f.numero as numero_fattura,
 f."prezzo" as importo_fattura,"CIG",
 "fattura / nota credito"::char(1) as fattura_o_nota_di_credito,
 "data fattura / nota credito"::date as data_emissione,
 "data pagamento"::date as data_pagamento,
 o.prezzo, o.commissione_sconto, o.totale, o.iva, o."prezzo finale" as prezzo_finale,
 o.numcopie, o.ordnum, o.ordanno, o.ordprogressivo,
 o.abbmesedal || '/' || o.abbannodal || '-' || o.abbmeseal || '/' || o.abbannoal as periodo,
 o.statodettaglio,
 o.tipo as formato, cc.note as note_interne
  from excel_files_tables.celdes_musicale_admin_report_ordini o
    left join excel_files_tables.ordini_periodici_musicale cc using(titolo)
    left join excel_files_tables.celdes_musicale_admin_report_ordini_con_dati_fatturazione
     f using(titolo)

UNION
-- musicale 2014
select 2014 as anno_fornitura,o.titolo, cc.manifestation_id, 3 as library_id, f.numero as numero_fattura,
 f."totale articolo" as importo_fattura,"CIG",
 "fattura / nota credito"::char(1) as fattura_o_nota_di_credito,
 "data fattura / nota credito"::date as data_emissione,
 "data pagamento"::date as data_pagamento,
 o.prezzo, o.commissione_sconto, o.totale, o.iva, o."prezzo finale" as prezzo_finale,
 o.numcopie, o.ordnum, o.ordanno, o.ordprogressivo,
 o.abbmesedal || '/' || o.abbannodal || '-' || o.abbmeseal || '/' || o.abbannoal as periodo,
 o.statodettaglio,
 o.tipo as formato, cc.note as note_interne
  from excel_files_tables.celdes_musicale_admin_report_ordini_2014 o
    left join excel_files_tables.ordini_periodici_musicale cc using(titolo)
    left join excel_files_tables.celdes_musicale_admin_report_ordini_con_dati_fatturazione_2014
     f using(titolo)
;


update public.serials_admin_table set fattura_o_nota_di_credito = upper(fattura_o_nota_di_credito);

alter table serials_admin_table add column id serial primary key;
update serials_admin_table set prezzo=null where prezzo='';


alter table serials_admin_table alter COLUMN ordanno set default extract(year from now());
