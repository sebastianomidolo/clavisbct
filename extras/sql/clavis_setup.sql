CREATE INDEX clavis_item_collocation_idx on clavis.item(collocation);
CREATE INDEX clavis_item_serieinv_idx on clavis.item(inventory_serie_id);
UPDATE clavis.manifestation SET bid_source='SBN_bad_bid' WHERE length(bid)!=10 and bid_source='SBN';

UPDATE clavis.manifestation SET bid_source='SBNBCT' WHERE bid_source = 'SBN' AND bid ~ '^BCT';

create index clavis_item_manifestation_id_ndx on clavis.item(manifestation_id);
-- create index clavis_item_title_ndx on clavis.item(to_tsvector('simple', title));

UPDATE clavis.patron SET opac_username = lower(opac_username) WHERE opac_enable='1';
CREATE INDEX clavis_patron_opac_username_idx on clavis.patron(opac_username) WHERE opac_enable='1';

CREATE INDEX item_title_idx ON clavis.item USING gin(to_tsvector('simple', title));

UPDATE clavis.item SET issue_status = NULL WHERE issue_status NOTNULL AND issue_id ISNULL;

CREATE INDEX item_owner_library_id_idx ON clavis.item(owner_library_id);
CREATE INDEX item_home_library_id_idx ON clavis.item(home_library_id);
CREATE INDEX item_section_idx ON clavis.item("section");
CREATE INDEX item_specification_idx ON clavis.item(specification);
CREATE INDEX item_supplier_id_idx ON clavis.item(supplier_id);
CREATE INDEX item_barcode_idx ON clavis.item(barcode);
CREATE INDEX item_barcode_item_status_idx ON clavis.item(barcode,item_status);

CREATE INDEX rfid_code_idx ON clavis.item(rfid_code);

CREATE INDEX item_request_item_id ON clavis.item_request(item_id);


CREATE TABLE clavis.uni856 AS
  SELECT manifestation_id,
  (xpath('//d856/su/text()',unimarc::xml))[1]::text AS url,
  (xpath('//d856/sz/text()',unimarc::xml))[1]::text AS nota
FROM clavis.manifestation WHERE (xpath('//d856/su/text()',unimarc::xml))[1] NOTNULL;
CREATE index uni856_manifestation_id_idx ON clavis.uni856(manifestation_id);

create table clavis.url_sbn
  as select manifestation_id
from clavis.manifestation where (unimarc ~ '<sa>&lt;URL&gt' or unimarc ~ '<d856');
alter table clavis.url_sbn add column url text;
alter table clavis.url_sbn add column nota text;
alter table clavis.url_sbn add column unimarc_tag char(3);
create index url_sbn_manifestation_id_idx on clavis.url_sbn(manifestation_id);

alter table clavis.item add column talking_book_id integer;
update clavis.item set talking_book_id = custom_field1::integer where custom_field1 ~ '^[0-9\.]+$'
  and  item_media='T' and section='LP';
create index item_talking_book_id_ndx on clavis.item(talking_book_id) where talking_book_id notnull;
  

CREATE INDEX clavis_authorities_full_text ON clavis.authority(full_text);
CREATE INDEX clavis_authorities_authority_id ON clavis.authority(authority_id);
CREATE INDEX clavis_authorities_subject_class ON clavis.authority(subject_class);
CREATE INDEX clavis_authorities_authority_type ON clavis.authority(authority_type);


UPDATE clavis.authority SET subject_class='no label' WHERE authority_type = 's' AND subject_class IS NULL;

CREATE TABLE clavis.manifestation_creators AS (SELECT DISTINCT created_by FROM clavis.manifestation);

ALTER TABLE clavis.item ALTER COLUMN inventory_serie_id DROP NOT NULL;


-- Da rimuovere una volta che le sezioni siano state inserite in Clavis
-- Vedi http://bctdoc.comperio.it/issues/237
-- Rimosso 29 gennaio 2016:
/*
INSERT INTO clavis.library_value(value_key,value_class,value_library_id,value_label)
            VALUES ('CCVT','ITEMSECTION',2,'CCVT (Viaggi e turismo)');
INSERT INTO clavis.library_value(value_key,value_class,value_library_id,value_label)
            VALUES ('CCNC','ITEMSECTION',2,'CCNC (Narrativa contemporanea)');
INSERT INTO clavis.library_value(value_key,value_class,value_library_id,value_label)
            VALUES ('CCTL','ITEMSECTION',2,'CCTL (Tempo libero: cinema, teatro, musica, danza)');
*/
-- INSERT INTO clavis.library_value(value_key,value_class,value_library_id,value_label)
--            VALUES ('BB','ITEMSECTION',2,'BB (Biblioteconomia e bibliografia)');


alter table clavis.item add column openshelf boolean;
update clavis.item set openshelf=true where item_id in (select item_id from open_shelf_items);
create index clavis_item_openshelf on clavis.item(openshelf) where openshelf is not null;

create index manifestation_edition_date on clavis.manifestation(edition_date);
create index clavis_attachment_object_id on clavis.attachment (object_id);

create or replace view soggetti_non_presenti_in_nuovo_soggettario as
  select s.subject_class,s.authority_id as subject_id,ca.authority_id,ca.full_text as heading
  from clavis.authority ca left join bncf_terms ns on(ns.term=ca.full_text)
  join clavis.authority s on (s.parent_id=ca.authority_id AND s.full_text=ca.full_text)
   where ca.authority_type = 'A' and ca.authority_rectype in ('k','x')
   and not ca.full_text ~ ',' and ns is null order by ca.sort_text;

create or replace view bio_iconografico_cards as
  select id,(xpath('//r/ns/text()',tags))[1]::varchar as namespace,
       (xpath('//r/l/text()',tags))[1]::varchar as lettera,
       (xpath('//r/n/text()',tags))[1]::text::integer as numero,
       (xpath('//r/parent/text()',tags))[1]::text::integer as parent
  from d_objects where type = 'BioIconograficoCard';

create or replace view bio_iconografico_topics_view as
  select id,(xpath('//r/intestazione/text()',tags))[1]::text as intestazione
  from bio_iconografico_topics;


create or replace view soggetti_mso_duplicati as
select c1.authority_id as mso_id,c1.subject_class as mso_class,c1.full_text as intestazione,
  c2.authority_id as other_id,c2.subject_class as other_class
  from clavis.authority c1 join clavis.authority c2
 on(c1.full_text=c2.full_text and c1.subject_class!=c2.subject_class) 
  where c1.subject_class='MSO' AND c2.subject_class !='MSO';



update clavis.item set sequence2=NULL where section = 'BCTA' and sequence2 = '(su prenotazione)';
update clavis.item set sequence2=NULL where section = 'BCTA' and sequence2 = '. (su prenotazione)';

REFRESH MATERIALIZED VIEW dobjects ;

create index l_authority_manifestation_manifestation_id_ndx on clavis.l_authority_manifestation (manifestation_id);
create index l_manifestation_manifestation_id_down_ndx on clavis.l_manifestation (manifestation_id_down);
-- create index clavis_item_custom_field1_ndx on clavis.item(custom_field1) where owner_library_id=-3 and custom_field1 notnull;


create table clavis.items_con_prenotazioni_pendenti as
select ci.item_id,array_agg(distinct ir.request_id) as request_ids,count(*)::integer as requests_count
from
clavis.item_request ir join clavis.manifestation cm
using(manifestation_id) join clavis.item ci using(manifestation_id)
where ir.request_status='A' and ci.manifestation_id!=0
AND ci.loan_class IN('A','B') and ci.loan_status = 'A'
AND ci.item_status IN ('B','F','K','S','V')
GROUP BY ci.item_id;

/*
loan_class
A - Non disponibile
B - Prestabile

item_status
F - Su scaffale
K - Novità
S - Non trovato da cercare
V - In vetrina
*/


create table clavis.unique_items as select i1.home_library_id,i1.item_id from clavis.item as i1
   left join clavis.item as i2 on(i1.manifestation_id=i2.manifestation_id and i1.item_id!=i2.item_id)
       where i1.manifestation_id != 0 AND i1.item_status!='E' AND i2.item_id is null;
alter table clavis.unique_items add primary key(item_id);

create index ean_clavis_purchase_proposal_ndx on clavis.purchase_proposal(ean) where ean!='';
create index ean_clavis_manifestation_ndx on clavis.manifestation("EAN") where "EAN"!='';
create index isbnissn_clavis_manifestation_ndx on clavis.manifestation("ISBNISSN") where "ISBNISSN"!='';


alter table clavis.item add column digitalized boolean;
update clavis.item set digitalized = true where manifestation_id in (select attachable_id from attachments
   where attachable_type = 'ClavisManifestation');


-- 17 aprile 2020
drop table if exists clavis.buchi_dvd;
create table clavis.buchi_dvd as
 select item_id,collocation,specification from clavis.item where item_media='Q' and collocation like 'DVD%' and owner_library_id=2;
update clavis.buchi_dvd set specification = NULL where specification='';
update clavis.buchi_dvd set collocation=replace(collocation, '/', ',') where specification is null and collocation ~ '/';
alter table clavis.buchi_dvd alter COLUMN specification type integer USING specification::integer;
update clavis.buchi_dvd set collocation=replace(collocation, ' ', '.')  where collocation ~ ' ' and specification is null;
update clavis.buchi_dvd set collocation=replace(collocation, ',', '.')  where collocation ~ ',' and specification is null;
delete from clavis.buchi_dvd where split_part(collocation, '.', 2) ~* '[a-z]';
update clavis.buchi_dvd set specification = split_part(collocation, '.', 2)::integer
where specification is null and split_part(collocation, '.', 2) ~ '\d';
delete from clavis.buchi_dvd where specification is null;

------------------
create index item_media_type_ndx on clavis.item(item_media);
create index item_status_ndx on clavis.item(item_status);
create index loan_patron_id_ndx on clavis.loan(patron_id);
