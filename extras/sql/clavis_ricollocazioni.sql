begin; drop table ricollocazioni; commit;
create table ricollocazioni as
select ci.item_id,ca.authority_id as class_id,ca.class_code || '.' ||
 CASE WHEN mainentry is null THEN
  upper(substr(trim(replace(cm.sort_text,'_','')),1,3))
 ELSE
  upper(substr(trim(replace(mainentry.sort_text,'_','')),1,3))
 END as "dewey_collocation",
 mainentry.authority_id
 from clavis.item ci
   join clavis.manifestation cm using(manifestation_id)
   left join clavis.l_authority_manifestation lam using(manifestation_id)
   join clavis.authority ca on(lam.authority_id=ca.authority_id AND ca.authority_type='C')
   left join clavis.l_authority_manifestation lam2 on(cm.manifestation_id=lam2.manifestation_id
         and lam2.link_type = 700)
   left join clavis.authority mainentry on (lam2.authority_id=mainentry.authority_id)
 where ci.owner_library_id=2;

CREATE INDEX ricollocazioni_item_id_ndx on ricollocazioni(item_id);
CREATE INDEX ricollocazioni_class_id_ndx on ricollocazioni(class_id);
CREATE INDEX ricollocazioni_authority_id_ndx on ricollocazioni(authority_id);

