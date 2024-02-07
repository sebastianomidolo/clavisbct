/* View scritta il 30 marzo 2023 */

drop view public.dinotola;
create or replace view public.dinotola as
  select
  cm.manifestation_id,
  cm."ISBNISSN" as isbn,
  main_entry.full_text as autore,
trim(cm.title) as titolo,
  cm.publisher as editore,
  cm.edition_date as anno_pubblicazione,
  cm.edition_language as lingua,
  cdd.class_code,
  ci.home_library_id,
  ci.item_status,
  ci.loan_class,
  ci.item_media,
  ci.item_id,
  ci.inventory_date,
  piano.piano,
  cc.collocazione,
  array_to_string(array_agg(distinct kw.full_text),' ; ') as keywords,
  array_to_string(array_agg(distinct trim(serie.title)),' ; ') as series,
  array_to_string(array_agg(distinct loans.cnt), ',')::integer as numero_prestiti

  from 
    clavis.manifestation cm
        join clavis.item ci on(ci.manifestation_id=cm.manifestation_id)
	join clavis.collocazioni cc on(cc.item_id=ci.item_id)
        left join clavis.centrale_locations piano on(piano.item_id=ci.item_id)

    left join clavis.l_authority_manifestation lam1 on(lam1.manifestation_id=cm.manifestation_id and lam1.link_type=676)
    left join clavis.authority cdd on(cdd.authority_id=lam1.authority_id)

    left join clavis.l_authority_manifestation lam2 on(lam2.manifestation_id=cm.manifestation_id and lam2.link_type=700)
    left join clavis.authority main_entry on(main_entry.authority_id=lam2.authority_id)

    left join clavis.l_authority_manifestation lam3 on(lam3.manifestation_id=cm.manifestation_id and lam3.link_type=619)
    left join clavis.authority kw on(kw.authority_id=lam3.authority_id)

    left join clavis.l_manifestation lm on(lm.manifestation_id_up=cm.manifestation_id and lm.link_type=410)
    left join clavis.manifestation serie on(serie.manifestation_id=lm.manifestation_id_down)

    LEFT JOIN LATERAL (SELECT count(loan_id) as cnt
       FROM clavis.loan WHERE item_id=ci.item_id and item_home_library_id=ci.home_library_id limit 1) as loans on true

where cm.bib_level='m'
and ci.item_status!='B' -- escludi esemplari in catalogazione
and ci.manifestation_id>0
-- and ci.item_media='F' -- solo esemplari in stato "su scaffale"

group by 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16
--, autore, titolo, editore, anno_pubblicazione, lingua, cdd.class_code, cm.manifestation_id,
-- main_entry, ci.home_library_id,ci.loan_class,ci.item_media,ci.item_id;
;



select * from dinotola where manifestation_id=19
-- and home_library_id=2
;

/* Si può poi generare una tabella con 
create table public.dinotola_centrale as select * from dinotola where home_library_id=2;
update dinotola_centrale set keywords = NULL where keywords='';
update dinotola_centrale set series = NULL where series='';
E spedire tutto su un file csv:

\o /home/storage/preesistente/static/collezione_centrale.csv
\copy (SELECT * FROM public.dinotola_centrale) TO stdout csv header
\o


*/


