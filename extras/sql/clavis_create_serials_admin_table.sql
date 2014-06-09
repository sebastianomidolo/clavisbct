begin;
DROP TABLE public.serials_admin_table;
commit;


UPDATE excel_files_tables.celdes_admin_report_ordini_con_dati_fatturazione set "data pagamento" = NULL
    WHERE "data pagamento"='';
UPDATE excel_files_tables.celdes_musicale_admin_report_ordini_con_dati_fatturazione set "data pagamento" = NULL
    WHERE "data pagamento"='';

CREATE TABLE public.serials_admin_table
AS
select g.titolo, cc.manifestation_id,b.library_id,f.numero as numero_fattura,
 f."totale articolo" as importo_fattura,
 "fattura / nota credito"::char(1) as fattura_o_nota_di_credito,
 "data fattura / nota credito"::date as data_emissione,
 "data pagamento"::date as data_pagamento,
 o.prezzodichiaratolit, o.prezzo, o.commissione_sconto, o.totale, o.iva, o."prezzo finale" as prezzo_finale,
 o.numcopie, o.ordnum, o.ordanno, o.ordprogressivo
  from excel_files_tables.celdes_gest_riepilogo_situazione_ordini g
   left join excel_files_tables.titoli_celdes_clavis cc using(titolo)
   join excel_files_tables.celdes_admin_report_ordini o using(titolo,ordnum,ordprogressivo)
   left join excel_files_tables.celdes_admin_report_ordini_con_dati_fatturazione f using(titolo,destinatario)
   join biblioteche_celdes b on(b.label=g.destinatario)
UNION
-- musicale
select o.titolo, cc.manifestation_id, 3 as library_id, f.numero as numero_fattura,
 f."totale articolo" as importo_fattura,
 "fattura / nota credito"::char(1) as fattura_o_nota_di_credito,
 "data fattura / nota credito"::date as data_emissione,
 "data pagamento"::date as data_pagamento,
 o.prezzodichiaratolit, o.prezzo, o.commissione_sconto, o.totale, o.iva, o."prezzo finale" as prezzo_finale,
 o.numcopie, o.ordnum, o.ordanno, o.ordprogressivo
  from excel_files_tables.celdes_musicale_admin_report_ordini o
    left join excel_files_tables.ordini_periodici_musicale cc using(titolo)
    left join excel_files_tables.celdes_musicale_admin_report_ordini_con_dati_fatturazione
     f using(titolo);

update public.serials_admin_table set fattura_o_nota_di_credito = upper(fattura_o_nota_di_credito);

