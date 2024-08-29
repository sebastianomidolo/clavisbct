-- Viste nuove create in gennaio 2024

set standard_conforming_strings to false;
set backslash_quote to 'safe_encoding';


-- NB: non dovrebbe esistere manifestation con id 0:

select now();
delete from clavis.manifestation where manifestation_id=0;


create unique index if not exists lookup_value_ndx on clavis.lookup_value (value_key,value_language,value_class);


-- Testi (105) Campo codificato unimarc 105
-- vedi http://unimarc-it.wikidot.com/105

-- Per velocizzare le cose, eventualmente creare tabella come segue:
create table if not exists clavis.uni105_4 as select manifestation_id,public.unimarc_105(unimarc::xml,4)::char(1) from clavis.manifestation;
create index if not exists uni105_4_manifestation_id_ndx on clavis.uni105_4(manifestation_id);
create index if not exists uni105_4_unimarc_105_ndx on clavis.uni105_4(unimarc_105);


CREATE OR REPLACE FUNCTION public.unimarc_105(unimarc_xml xml, pos integer) RETURNS char AS $$
DECLARE
 coded_dat char;
 BEGIN
  SELECT substr((xpath('//d105/sa/text()',unimarc_xml::xml))[1]::char(14),pos+1,1) into coded_dat;
 RETURN coded_dat;
 END;
$$ LANGUAGE plpgsql;


DROP VIEW IF EXISTS clavis.view_patrimonio;
CREATE OR REPLACE VIEW clavis.view_patrimonio as

SELECT

case when ci.owner_library_id = -1 then -ci.item_id else ci.item_id end as item_id,

case when ci.owner_library_id = -1 then ci.custom_field3 end as topogr_id,

case when ci.inventory_serie_id != '' then ci.inventory_serie_id end as inventory_serie_id,

ci.inventory_number,cm.manifestation_id,cm.bib_level,cm.bib_type,cm.edition_date,

-- case when ci.inventory_date is null then ci.date_created else ci.inventory_date end as inventory_date,

ci.date_created, ci.inventory_date,

-- cdd.link_type,cdd.authority_id,
cdd.class_code,upclass.up_class_code,ci.date_discarded,
cc.primo as primo_elemento_collocazione,

loans_info.*,
loans_info_totale.*,
last_loans.loan_date_begin as ultimo_prestito,

case when
   not cc.collocazione ~ E'^P\\.G\\.'
   and (
    ci.inventory_serie_id = 'PIE'
    or  cc.primo IN ('P','PC','CCPT')
    or  ( cc.secondo = 'P' and ci.home_library_id!=3 )
    or  (
          ci.home_library_id = 2 and length(cc.secondo)=1
           and
	  ( cc.primo_i between 251 and 265 OR cc.primo_i IN (407,667) )
	)
   )
then true else false end as piemonte,


case
  when cm.bib_type='i02' then 'CDi02'
  when cm.bib_type='j02' then 'CDj02'
  when ci.item_media = 'A' then 'Audiovisivi'
  when ci.item_media = 'T' then 'Libri parlati'
  when ci.item_media = 'Q' then 'DVD'
  when ci.loan_class = 'F' then 'Consultazione'
  when cc.collocazione ~ (E'^Cons\\.|^RC|^R\\.C') then 'Consultazione'
  else
  case
    when cc.primo not in ('RN','R','RC') then
      case
        when cc.primo IN ('CCNC','N') then 'Narrativa'
        when cc.primo = 'NG' then 'Narrativa NG'
 	when cc.primo = 'NF' then 'Narrativa NF'
 	when cc.primo = 'NR' then 'Narrativa NR'
        when ci.owner_library_id=2 and (ci.inventory_serie_id='RAG' OR u.unimarc_105 = 'r') then
          case
            when occ.primo = 'RN' and occ.terzo_i   between 1 and 19 then occ.primo || '.' || occ.terzo
            when occ.primo = 'RN' and occ.secondo_i between 1 and 19 then occ.primo || '.' || occ.secondo
            when occ.primo = 'R' then
              case
                when cdd.class_code IS NULL then
	          occ.primo || '.' || substr(occ.secondo,1,1) || '00'
                else
                  occ.primo || '.' || substr(cdd.class_code,1,1) || '00'
              end
	    else 'rag_check'
	  end
        when cdd.class_code IS NOT NULL then substr(cdd.class_code,1,1) || '00'
        else
	case
	  when upclass.up_class_code IS NOT NULL then substr(upclass.up_class_code,1,1) || '00'
	  else 'A_NonClassif'
	end
      end
    else -- potenzialmente ragazzi
    case
      when cc.secondo = 'Tattili' then cc.secondo
      when cc.primo = 'RN' and cc.terzo_i    between 1 and 19 then cc.primo || '.' || cc.terzo
      when cc.primo = 'RN' and cc.secondo_i  between 1 and 19 then cc.primo || '.' || cc.secondo
      when cc.primo = 'RC' then 'Tipo_RC'
      when cc.primo = 'R' AND cc.secondo='C' then 'Tipo_R.C.'
      when cc.primo = 'R' then
        case
	   when cdd.class_code IS NULL then
	     cc.primo || '.' || substr(cc.secondo,1,1) || '00'
	   else cc.primo || '.' || substr(cdd.class_code,1,1) || '00'
	end
      else 'R_NonClassif'
    end
  end
end as statcol,

   cc.collocazione as colloc_stringa, ci.collocation as colloc_clavis, occ.collocazione as coll_rag, occ.home_library_id as coll_rag_library_id,
   occ.secondo_i as coll_rag_secondo_i,
   occ.item_id as coll_rag_item_id,
   ci.item_media, lv1.value_label as item_media_label,
   ci.item_status,lv2.value_label as item_status_label,
   ci.loan_class, lv3.value_label as loan_class_label,
   ci.section,
   ci.home_library_id,
   lc1.label home_library,
   ci.owner_library_id,lc2.label as owner_library,
   u.unimarc_105,
   case when
     ( (ci.section in ('R','RN','CAA')) OR (cc.collocazione ~ (E'^R|^DVD\\.R\\.|^DVD\\.RN\\.') ) )
        OR
     ( (ci.owner_library_id=2 and ci.inventory_serie_id='RAG') )
        OR      ( u.unimarc_105 = 'r' )
     then 'ragazzi'
     else 'adulti'
   end as pubblico,

   case
     when cc.collocazione ~ (E'^Cons\\.|^RC\\.|^RC ') then NULL
     else
      case
       when (ci.section in ('RN','CCNC','N','NG')) OR (cc.collocazione ~ (E'^RN|^R\\.N|^N') )
        then 'narrativa'
        else 'saggistica'
     end
   end as genere

   FROM clavis.item AS ci
    JOIN sbct_acquisti.library_codes lc1 ON(lc1.clavis_library_id=ci.home_library_id  and lc1.owner='bct')

    --     LEFT JOIN sbct_acquisti.library_codes lc2 ON(lc2.clavis_library_id=ci.owner_library_id and lc2.owner='bct')

    LEFT JOIN sbct_acquisti.library_codes lc2 ON(lc2.clavis_library_id=ci.owner_library_id)
    
      LEFT JOIN clavis.collocazioni AS  cc ON(cc.item_id=ci.item_id)
      LEFT JOIN clavis.manifestation AS cm ON(cm.manifestation_id=ci.manifestation_id and cm.bib_level='m')
      LEFT JOIN clavis.uni105_4 u ON(u.manifestation_id=cm.manifestation_id)

      LEFT JOIN clavis.lookup_value lv1 on(lv1.value_key=ci.item_media  AND lv1.value_language = 'it_IT' AND lv1.value_class = 'ITEMMEDIATYPE')
      LEFT JOIN clavis.lookup_value lv2 on(lv2.value_key=ci.item_status AND lv2.value_language = 'it_IT' AND lv2.value_class = 'ITEMSTATUS')
      LEFT JOIN clavis.lookup_value lv3 on(lv3.value_key=ci.loan_class AND lv3.value_language = 'it_IT' AND lv3.value_class = 'LOANCLASS')


--      LEFT JOIN clavis.l_authority_manifestation AS lam ON(lam.manifestation_id=cm.manifestation_id and lam.link_type=676)
--      LEFT JOIN clavis.authority AS au USING(authority_id)

   LEFT JOIN LATERAL
     (SELECT lam.link_type, au.authority_id, regexp_replace(au.class_code, E'\\s|\\t', '', 'g') as class_code
       FROM clavis.l_authority_manifestation AS lam
       LEFT JOIN clavis.authority AS au USING(authority_id)
        WHERE lam.manifestation_id=cm.manifestation_id and lam.link_type=676
       order by class_code limit 1) as cdd on true

     LEFT JOIN LATERAL
        (SELECT xc.collocazione,oci.home_library_id,xc.primo,xc.secondo,xc.terzo,xc.secondo_i,xc.terzo_i,xc.item_id
        FROM clavis.item AS oci JOIN clavis.collocazioni AS xc using(item_id)
           JOIN sbct_acquisti.library_codes ON(clavis_library_id=oci.home_library_id AND owner='bct')
	 WHERE oci.manifestation_id = cm.manifestation_id and oci.home_library_id!=ci.home_library_id
	    AND xc.collocazione ~ '^R' AND oci.item_status != 'E'
	    AND oci.item_id != ci.item_id and ci.owner_library_id>0 limit 1) as occ on true


     LEFT JOIN LATERAL
     (SELECT lam.link_type as up_link_type, au.authority_id as up_authority_id, regexp_replace(au.class_code, E'\\s|\\t', '', 'g') as up_class_code
        FROM clavis.l_manifestation clm
	   LEFT JOIN clavis.l_authority_manifestation AS lam ON (lam.manifestation_id=clm.manifestation_id_down)
          LEFT JOIN clavis.authority AS au USING(authority_id)
        WHERE lam.manifestation_id=clm.manifestation_id_down and lam.link_type=676
           and manifestation_id_up = cm.manifestation_id AND clm.link_type = 461
       order by class_code limit 1) as upclass on true


      -- NB: create index clavis_loan_item_id_ndx on clavis.loan(item_id)
  LEFT JOIN LATERAL
    (select count(*) as prestiti, array_to_string(array_agg(DISTINCT date_part('year', cl.loan_date_begin)
       ORDER BY date_part('year', cl.loan_date_begin)), ',') as anni_prestito
     FROM clavis.loan cl WHERE cl.item_id=ci.item_id) as loans_info on true

      -- NB: create index clavis_loan_manifestation_id_ndx on clavis.loan(manifestation_id)
  LEFT JOIN LATERAL
    (select count(*) as prestiti_totale, array_to_string(array_agg(DISTINCT date_part('year', cl.loan_date_begin)
       ORDER BY date_part('year', cl.loan_date_begin)), ',') as anni_prestito_totale
     FROM clavis.loan cl WHERE cl.manifestation_id = cm.manifestation_id ) as loans_info_totale on true


   LEFT JOIN LATERAL
     (SELECT cl.loan_date_begin FROM clavis.loan cl WHERE cl.item_id=ci.item_id
        and cl.loan_date_begin is not null
       order by cl.loan_date_begin desc limit 1) as last_loans on true

      WHERE ci.item_media != 'S' AND ci.item_status != 'E'
       and ci.owner_library_id != -3;


-- select * from clavis.view_patrimonio  where manifestation_id = 643608;



-- select item_id,genere,pubblico,statcol,statcol,colloc_stringa from clavis.view_patrimonio limit 20;

/*
Chiedere a Daniela:

select count(*) from view_patrimonio where authority_id notnull and classif = 'ERROR' ;
Manca class_code
17 casi, perché?


Poi:
select count(*) from view_patrimonio p join clavis.uni105_4 u using(manifestation_id) where p.pubblico='adulti' and u.unimarc_105='r';           
 count 
-------
 21195
Giusto o sbagliato? O entrambi?
Verifica per biblioteca:
select p.home_library_id,count(*) from view_patrimonio p join clavis.uni105_4 u using(manifestation_id) where p.pubblico='adulti' and u.unimarc_105='r' group by p.home_library_id;          

Esempio bib 1121:
select * from view_patrimonio where home_library_id = 1121 and pubblico='adulti' and unimarc_105='r';


clavisbct_development=> select pubblico,count(*) from view_patrimonio group by rollup(1);
 pubblico |  count  
----------+---------
 adulti   | 1287884
 ragazzi  |  199973
          | 1487857


Verificare topografico:
select home_library_id,count(*) from clavis.item where owner_library_id = -1 and not title ~* 'non occupare|spazio libero'  group by rollup(1);

select item_id,colloc_stringa from view_patrimonio where owner_library_id>0 and classif is null and colloc_stringa ~ '^\d\d\d'  limit 10000;



*/

-- select * from view_patrimonio where manifestation_id = 269702;

create or replace view public.view_bibliobct as
  select c.label,c.owner,l.library_id,l.label as biblioteca
   from sbct_acquisti.library_codes c join
         clavis.library l on (l.library_id=c.clavis_library_id);


-- select owner_library,cl.shortlabel,count(*) from clavis.view_patrimonio p left join clavis.library cl on (cl.library_id=p.owner_library_id) group by 1,2;

drop table stats.new_patrimonio ;
select now();
create table stats.new_patrimonio as select * from clavis.view_patrimonio;
alter table stats.new_patrimonio add primary key (item_id);
select now();


/*
DROP VIEW IF EXISTS clavis.vp;
CREATE VIEW clavis.vp as
(
select statcol,item_id,manifestation_id as man_id,bib_level as blev,class_code as dewey,loan_class,
 substr(trim(colloc_stringa),1,24) as colloc,
 substr(trim(coll_rag),1,24) as collrag,
 inventory_serie_id as serie,item_media as media,item_status as status,section,
 loan_class as lc,
 home_library_id as homelib,owner_library_id as ownerlib,unimarc_105 as "uni105",pubblico,genere
 from stats.new_patrimonio);
*/

select * from clavis.view_patrimonio where item_id=459289;
