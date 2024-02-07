-- Viste nuove create in gennaio 2024


-- NB: non dovrebbe esistere manifestation con id 0:
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

SELECT ci.item_id,cm.manifestation_id,cm.bib_level,
cdd.link_type,cdd.authority_id,cdd.class_code,
ci.date_discarded,

/*
case when cc.primo = 'RN'
 then
   case when cc.terzo_i between 1 and 19 then cc.primo || '.' || cc.terzo else cc.primo || '.' || cc.secondo end
   else
case when cdd.class_code is null
 then 
   NULL
 else
  case when cdd.class_code = ''
   then
    'ERROR'
   else
    substr(cdd.class_code,1,1) || '00'
   end
 end
   --
 end
as statcoll,
*/

-- case
--   when cc.primo not in ('RN','R') then
--     case
--       when cc.primo IN ('CCNC','N','NG') then 'Narrativa'
--       when ci.inventory_serie_id = 'PIE' and ci.home_library_id=2 then 'Piemonte'
--       when cdd.class_code IS NULL then 'NonClassif'
--       else substr(cdd.class_code,1,1) || '00'
--     end
--   else
--     case
--      when cc.secondo = 'Tattili' then cc.secondo
--      when cc.primo = 'RN' then
--        case
--          when cc.terzo_i    between 1 and 19 then cc.primo || '.' || cc.terzo
--          when cc.secondo_i  between 1 and 19 then cc.primo || '.' || cc.secondo
--          -- when cc.primo = 'R' then cc.primo || '.' || substr(cdd.class_code,1,1) || '00' else 'x'
--        end
--      when cc.primo = 'R' then
--          cc.primo || '.' || substr(cdd.class_code,1,1) || '00'
--      end
-- end as statcollnew,

case
  when cc.primo not in ('RN','R') then
    case
      when cc.primo IN ('CCNC','N','NG') then 'Narrativa'
      when ci.inventory_serie_id = 'PIE' and ci.home_library_id=2 then 'Piemonte'
      when ci.owner_library_id=2 and (ci.inventory_serie_id='RAG' OR u.unimarc_105 = 'r')
         then
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
      else 'A_NonClassif'
    end
  else
    case
      when cc.secondo = 'Tattili' then cc.secondo
      when cc.primo = 'RN' and cc.terzo_i    between 1 and 19 then cc.primo || '.' || cc.terzo
      when cc.primo = 'RN' and cc.secondo_i  between 1 and 19 then cc.primo || '.' || cc.secondo
      when cc.primo = 'R' then
        case
	   when cdd.class_code IS NULL then
	     cc.primo || '.' || substr(cc.secondo,1,1) || '00'
	   else
             cc.primo || '.' || substr(cdd.class_code,1,1) || '00'
	end
      else 'R_NonClassif'
    end
end as statcol,

case when cdd.class_code is null
 then 
   NULL
 else
  case when cdd.class_code = ''
   then
    'ERROR'
   else
    substr(cdd.class_code,1,1) || '00'
   end
 end
 as classif,
   cc.collocazione as colloc_stringa, ci.collocation as colloc_clavis, occ.collocazione as coll_rag, occ.home_library_id as coll_rag_library_id,
   occ.secondo_i as coll_rag_secondo_i,
   occ.item_id as coll_rag_item_id,
   ci.inventory_serie_id as serieinv,
   ci.item_media, lv1.value_label as item_media_label,
   ci.item_status,lv2.value_label as item_status_label,
   ci.loan_class, lv3.value_label as loan_class_label,
   --    lv3.*,
   ci.section,
   ci.home_library_id,lc1.label as home_library,
   ci.owner_library_id,lc2.label as owner_library,
   -- 1 as owner_library_id,
   u.unimarc_105,
   case when
        ( (ci.section in ('R','RN','CAA')) OR (cc.collocazione ~ ('^R\.|^R |^RN\.|^RN |^RC\.|^RC |^DVD\.R\.|^DVD\.RN\.') ) )
        OR
      ( (ci.owner_library_id=2 and ci.inventory_serie_id='RAG') )
         OR      ( u.unimarc_105 = 'r' )
     then 'ragazzi'
     else 'adulti'
   end as pubblico,

   case
     when cc.collocazione ~ ('^Cons\.|^RC\.|^RC ') then 'consultazione'
     else
      case
       when (ci.section in ('RN','CCNC','N','NG')) OR (cc.collocazione ~ ('^RN\.|^RN ') )
        then 'narrativa'
        else 'saggistica'
     end
   end as genere

   FROM clavis.item AS ci
      JOIN sbct_acquisti.library_codes lc1 ON(lc1.clavis_library_id=ci.home_library_id and lc1.owner='bct')
      JOIN sbct_acquisti.library_codes lc2 ON(lc2.clavis_library_id=ci.owner_library_id and lc2.owner='bct')
      LEFT JOIN clavis.collocazioni cc ON(cc.item_id=ci.item_id)
      LEFT JOIN clavis.manifestation AS cm ON(cm.manifestation_id=ci.manifestation_id)
      LEFT JOIN clavis.uni105_4 u ON(u.manifestation_id=cm.manifestation_id)

      LEFT JOIN clavis.lookup_value lv1 on(lv1.value_key=ci.item_media  AND lv1.value_language = 'it_IT' AND lv1.value_class = 'ITEMMEDIATYPE')
      LEFT JOIN clavis.lookup_value lv2 on(lv2.value_key=ci.item_status AND lv2.value_language = 'it_IT' AND lv2.value_class = 'ITEMSTATUS')
      LEFT JOIN clavis.lookup_value lv3 on(lv3.value_key=ci.loan_class AND lv3.value_language = 'it_IT' AND lv3.value_class = 'LOANCLASS')


--      LEFT JOIN clavis.l_authority_manifestation AS lam ON(lam.manifestation_id=cm.manifestation_id and lam.link_type=676)
--      LEFT JOIN clavis.authority AS au USING(authority_id)

   LEFT JOIN LATERAL
     (SELECT lam.link_type, au.authority_id, regexp_replace(au.class_code, E'\\s|\\t', '', 'g') as class_code

       /*
        Da valutare:
        CASE WHEN au.class_code LIKE cc.collocazione
         THEN au.class_code
	 ELSE NULL
	END as class_code
       */

       FROM clavis.l_authority_manifestation AS lam
       LEFT JOIN clavis.authority AS au USING(authority_id)
        WHERE lam.manifestation_id=cm.manifestation_id and lam.link_type=676
       order by class_code limit 1) as cdd on true

     LEFT JOIN LATERAL
        (SELECT xc.collocazione,oci.home_library_id,xc.primo,xc.secondo,xc.terzo,xc.secondo_i,xc.terzo_i,xc.item_id
        FROM clavis.item AS oci JOIN clavis.collocazioni AS xc using(item_id)
           JOIN sbct_acquisti.library_codes ON(clavis_library_id=oci.home_library_id)
	 WHERE oci.manifestation_id = cm.manifestation_id and oci.home_library_id!=ci.home_library_id
	    AND xc.collocazione ~ '^R' AND oci.item_status != 'E'
	    AND oci.item_id != ci.item_id and ci.owner_library_id>0 limit 1) as occ on true


      WHERE ci.item_media != 'S'
--       AND ci.owner_library_id > 0
 --      AND ci.owner_library_id in (select clavis_library_id from sbct_acquisti.library_codes where owner='bct')
--      AND ci.item_status NOT IN ('E','H')

      AND ci.item_status != 'E'
 ;

-- select count(*) from clavis.view_patrimonio;

-- select * from clavis.view_patrimonio  where manifestation_id = 226;



select item_id,
-- manifestation_id,
genere,pubblico,statcol,
classif,colloc_stringa from clavis.view_patrimonio limit 20;

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


