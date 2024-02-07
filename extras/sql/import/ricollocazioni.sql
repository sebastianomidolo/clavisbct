SET SEARCH_PATH TO import;

drop table if exists ricollocazioni;

create table ricollocazioni as

select ci.item_id,ca.authority_id as class_id,ca.class_code || '.' ||
 CASE WHEN mainentry is null THEN
   CASE WHEN up_mainentry is null THEN
     upper(substr(trim(replace(cm.sort_text,'_','')),1,3))
   ELSE
     upper(substr(trim(replace(up_mainentry.sort_text,'_','')),1,3))
   END
 ELSE
  upper(substr(trim(replace(mainentry.sort_text,'_','')),1,3))
 END as "dewey_collocation",

 CASE WHEN mainentry is null THEN
   CASE WHEN up_mainentry is null THEN
    upper(substr(trim(regexp_replace(regexp_replace(cm.sort_text,'(,[ A-Z]*)$',''),E'\'|_|\\*|,','')),1,4)) 
   ELSE
    upper(substr(trim(regexp_replace(regexp_replace(up_mainentry.sort_text,'(,[ A-Z]*)$',''),E'\'|_|\\*|,','')),1,4)) 
   END

 ELSE 
  upper(substr(trim(regexp_replace(regexp_replace(mainentry.sort_text, '(,[ A-Z]*)$',''),E'\'|_|\\*|,','')),1,4))
 END as "vedetta",

 CASE WHEN up_mainentry is null THEN
   mainentry.authority_id
 ELSE
   up_mainentry.authority_id 
 END as authority_id,

 ''::text as sort_text

 from item ci
   join manifestation cm using(manifestation_id)
   left join l_authority_manifestation lam using(manifestation_id)
   join authority ca on(lam.authority_id=ca.authority_id AND ca.authority_type='C')
   left join l_authority_manifestation lam2 on(cm.manifestation_id=lam2.manifestation_id
         and lam2.link_type = 700)
   left join authority mainentry on (lam2.authority_id=mainentry.authority_id)
   left join l_manifestation up_man on(up_man.manifestation_id_down=cm.manifestation_id)

   left join l_authority_manifestation lam3 on(up_man.manifestation_id_up=lam3.manifestation_id
         and lam3.link_type = 700)

   left join authority up_mainentry on (lam3.authority_id=up_mainentry.authority_id)

 where ci.home_library_id=2
;


UPDATE ricollocazioni set sort_text=public.espandi_dewey(trim(dewey_collocation));

CREATE INDEX ricollocazioni_item_id_ndx on ricollocazioni(item_id);
CREATE INDEX ricollocazioni_sort_text_ndx on ricollocazioni(sort_text);
CREATE INDEX ricollocazioni_class_id_ndx on ricollocazioni(class_id);
CREATE INDEX ricollocazioni_authority_id_ndx on ricollocazioni(authority_id);

