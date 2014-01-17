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

ALTER TABLE clavis.collocazioni add primary key(item_id);
CREATE INDEX collocazioni_idx ON clavis.collocazioni(collocazione);
CREATE INDEX collocazioni_sort_text_idx ON clavis.collocazioni(sort_text);
CREATE INDEX item_owner_library_id_idx ON clavis.item(owner_library_id);
CREATE INDEX item_section_idx ON clavis.item("section");
CREATE INDEX item_specification_idx ON clavis.item(specification);







