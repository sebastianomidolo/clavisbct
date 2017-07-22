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
CREATE INDEX item_section_idx ON clavis.item("section");
CREATE INDEX item_specification_idx ON clavis.item(specification);
CREATE INDEX item_supplier_id_idx ON clavis.item(supplier_id);

CREATE INDEX rfid_code_idx ON clavis.item(rfid_code);

CREATE TABLE clavis.uni856 AS
  SELECT manifestation_id,
  (xpath('//d856/su/text()',unimarc::xml))[1]::varchar(128) AS url,
  (xpath('//d856/sz/text()',unimarc::xml))[1]::varchar(128) AS nota
FROM clavis.manifestation WHERE (xpath('//d856/su/text()',unimarc::xml))[1] NOTNULL;
CREATE index uni856_manifestation_id_idx ON clavis.uni856(manifestation_id);



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
       (xpath('//r/n/text()',tags))[1]::text::integer as numero
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


REFRESH MATERIALIZED VIEW dobjects ;
