CREATE INDEX clavis_item_collocation_idx on clavis.item(collocation);
update clavis.manifestation SET bid_source='SBN_bad_bid' where length(bid)!=10 and bid_source='SBN';


create index clavis_item_manifestation_id_ndx on item(manifestation_id);
create index clavis_item_title_ndx on item(to_tsvector('simple', title));

UPDATE clavis.patron SET opac_username = lower(opac_username) WHERE opac_enable='1';
CREATE INDEX clavis_patron_opac_username_idx on clavis.patron(opac_username) WHERE opac_enable='1';
