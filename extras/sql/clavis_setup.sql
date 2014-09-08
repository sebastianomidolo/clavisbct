CREATE INDEX clavis_item_collocation_idx on clavis.item(collocation);
CREATE INDEX clavis_item_serieinv_idx on clavis.item(inventory_serie_id);
UPDATE clavis.manifestation SET bid_source='SBN_bad_bid' WHERE length(bid)!=10 and bid_source='SBN';

UPDATE clavis.manifestation SET bid_source='SBNBCT' WHERE bid_source = 'SBN' AND bid ~ '^BCT';

create index clavis_item_manifestation_id_ndx on clavis.item(manifestation_id);
-- create index clavis_item_title_ndx on clavis.item(to_tsvector('simple', title));

UPDATE clavis.patron SET opac_username = lower(opac_username) WHERE opac_enable='1';
CREATE INDEX clavis_patron_opac_username_idx on clavis.patron(opac_username) WHERE opac_enable='1';

CREATE INDEX item_title_idx ON clavis.item USING gin(to_tsvector('simple', title));


CREATE TABLE clavis.collocazioni AS
  SELECT item_id, public.compact_collocation("section",collocation,specification,
    sequence1,sequence2) AS collocazione, ''::text as sort_text
   FROM clavis.item;

DELETE FROM clavis.collocazioni WHERE collocazione='';
UPDATE clavis.collocazioni SET sort_text = espandi_collocazione(collocazione);

UPDATE clavis.item SET issue_status = NULL WHERE issue_status NOTNULL AND issue_id ISNULL;

ALTER TABLE clavis.collocazioni add primary key(item_id);
CREATE INDEX collocazioni_idx ON clavis.collocazioni(collocazione);
CREATE INDEX collocazioni_sort_text_idx ON clavis.collocazioni(sort_text);
CREATE INDEX item_owner_library_id_idx ON clavis.item(owner_library_id);
CREATE INDEX item_section_idx ON clavis.item("section");
CREATE INDEX item_specification_idx ON clavis.item(specification);

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

