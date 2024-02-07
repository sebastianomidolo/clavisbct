UPDATE import.manifestation SET bid_source='SBN_bad_bid' WHERE length(bid)!=10 and bid_source='SBN';

UPDATE import.manifestation SET bid_source='SBNBCT' WHERE bid_source = 'SBN' AND bid ~ '^BCT';

UPDATE import.patron SET opac_username = lower(opac_username) WHERE opac_enable='1';

UPDATE import.item SET issue_status = NULL WHERE issue_status NOTNULL AND issue_id ISNULL;

CREATE TABLE import.uni856 AS
  SELECT manifestation_id,
  (xpath('//d856/su/text()',unimarc::xml))[1]::text AS url,
  (xpath('//d856/sz/text()',unimarc::xml))[1]::text AS nota
FROM import.manifestation WHERE (xpath('//d856/su/text()',unimarc::xml))[1] NOTNULL;

create table import.url_sbn (manifestation_id integer, url text, nota text, unimarc_tag char(3));

alter table import.item add column talking_book_id integer;
update import.item set talking_book_id = custom_field1::integer where custom_field1 ~ '^[0-9\.]+$'
  and  item_media='T' and section='LP';

UPDATE import.authority SET subject_class='no label' WHERE authority_type = 's' AND subject_class IS NULL;

CREATE TABLE import.manifestation_creators AS (SELECT DISTINCT created_by FROM import.manifestation);

ALTER TABLE import.item ALTER COLUMN inventory_serie_id DROP NOT NULL;

alter table import.item add column openshelf boolean;
update import.item set openshelf=true where item_id in (select item_id from open_shelf_items);

update import.item set sequence2=NULL where section = 'BCTA' and sequence2 = '(su prenotazione)';
update import.item set sequence2=NULL where section = 'BCTA' and sequence2 = '. (su prenotazione)';

create table import.items_con_prenotazioni_pendenti as
select ci.item_id,array_agg(distinct ir.request_id) as request_ids,count(*)::integer as requests_count
from
import.item_request ir join import.manifestation cm
using(manifestation_id) join import.item ci using(manifestation_id)
where ir.request_status='A' and ci.manifestation_id!=0
AND ci.loan_class IN('A','B') and ci.loan_status = 'A'
AND ci.item_status IN ('B','F','K','S','V')
GROUP BY ci.item_id;

create table import.unique_items as select i1.home_library_id,i1.item_id from import.item as i1
   left join import.item as i2 on(i1.manifestation_id=i2.manifestation_id and i1.item_id!=i2.item_id)
       where i1.manifestation_id != 0 AND i1.item_status!='E' AND i2.item_id is null;
alter table import.unique_items add primary key(item_id);

alter table import.item add column digitalized boolean;
update import.item set digitalized = true where manifestation_id in (select attachable_id from attachments
   where attachable_type = 'ClavisManifestation');

ALTER TABLE import.item ADD COLUMN acquisition_year integer;
UPDATE import.item SET acquisition_year = ay.year
 FROM public.estremi_registri_inventariali ay WHERE inventory_serie_id='V'
  AND acquisition_year IS NULL AND ABS(inventory_number) BETWEEN range_from AND range_to;

drop table if exists import.buchi_dvd;
create table import.buchi_dvd as
 select item_id,collocation,specification from import.item where item_media='Q' and collocation like 'DVD%' and owner_library_id=2;
update import.buchi_dvd set specification = NULL where specification='';
update import.buchi_dvd set collocation=replace(collocation, '/', ',') where specification is null and collocation ~ '/';
alter table import.buchi_dvd alter COLUMN specification type integer USING specification::integer;
update import.buchi_dvd set collocation=replace(collocation, ' ', '.')  where collocation ~ ' ' and specification is null;
update import.buchi_dvd set collocation=replace(collocation, ',', '.')  where collocation ~ ',' and specification is null;
delete from import.buchi_dvd where split_part(collocation, '.', 2) ~* '[a-z]';
update import.buchi_dvd set specification = split_part(collocation, '.', 2)::integer
where specification is null and split_part(collocation, '.', 2) ~ '\d';
delete from import.buchi_dvd where specification is null;

-- Creazione temporanea biblioteca Ferrante Aporti per inserimento in ordine periodici 2022-23
-- (biblioteca non ancora presente in Clavis, valutare se inserirla)
insert into import.library(library_id,library_class,consortia_id,description,label,
   shortlabel,library_type,library_internal,library_status,ill_code)
    (select 999999,library_class,consortia_id,'999999 - Biblioteca presso Istituto Ferrante Aporti',
      '999999 - Ferrante Aporti','FerranteAp',library_type,library_internal,library_status,'nocode'
       from import.library where library_id=21);
insert into import.l_library_librarian (library_id,librarian_id,link_role,opac_visible)values (999999,13,0,0);
insert into import.l_library_librarian (library_id,librarian_id,link_role,opac_visible)values (999999,3,0,0);

create temp table import_r1 as (select manifestation_id,count(*) as reqnum from import.item_request
     where manifestation_id!=0 and item_id is null and request_status='A'
      group by manifestation_id);
create temp table import_i1 as (select manifestation_id,array_length(array_agg(distinct item_id),1) as available_items
     from import.item where manifestation_id in (select manifestation_id from import_r1)
       and loan_class IN ('B')
       and item_status IN ('B','F','G','K','S','V')
        group by manifestation_id);
    
create table import.piurichiesti as
select  *, round((available_items::numeric / reqnum::numeric)*100,2) as percentuale_di_soddisfazione
  from import_r1 join import_i1 using(manifestation_id) where reqnum>available_items;


alter table import.purchase_proposal add column sbct_title_id integer;
alter table import.purchase_proposal ADD CONSTRAINT fk_sbct_titles FOREIGN KEY (sbct_title_id)
   REFERENCES sbct_acquisti.titoli on update cascade on delete set null;
update import.purchase_proposal pp set sbct_title_id = t.id_titolo from sbct_acquisti.titoli t where t.ean=pp.ean;

insert into sbct_acquisti.l_clavis_purchase_proposals_titles (id_titolo,proposal_id)
   (select sbct_title_id,proposal_id from import.purchase_proposal where sbct_title_id notnull)
     on conflict do nothing;

update import.supplier set vat_code=NULL where vat_code='';

create table import.last_item_actions as select * from import.item_action where action_type='I' and date_created > now() - interval '12 months';
create table import.last_notifications as select * from import.notification where notification_class='F' and date_created > now() - interval '12 months';
alter table import.last_notifications add primary key(notification_id);
alter table import.last_item_actions  add primary key(item_action_id);
