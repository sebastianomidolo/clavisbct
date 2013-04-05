CREATE INDEX clavis_item_collocation_idx on clavis.item(collocation);
update clavis.manifestation SET bid_source='SBN_bad_bid' where length(bid)!=10 and bid_source='SBN';

