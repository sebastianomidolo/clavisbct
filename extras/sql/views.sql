-- Viste nuove create in gennaio 2024


-- NB: non dovrebbe esistere manifestation con id 0:
delete from clavis.manifestation where manifestation_id=0;


-- Testi (105) Campo codificato unimarc 105
-- vedi http://unimarc-it.wikidot.com/105

-- Per velocizzare le cose, eventualmente creare tabella come segue:
create table if not exists clavis.uni105_4 as select manifestation_id,public.unimarc_105(unimarc::xml,4) from manifestation;
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


DROP VIEW clavis.view_patrimonio;
CREATE OR REPLACE VIEW clavis.view_patrimonio as

SELECT ci.item_id,cm.manifestation_id,lam.link_type,au.authority_id,
au.class_code,
case when au.class_code is null
 then 
   NULL
 else
  case when au.class_code = ''
   then
    'ERROR'
   else
    substr(au.class_code,1,1) || '00'
   end
 end
 as classif,
   cc.collocazione as colloc_stringa, ci.collocation as colloc_clavis,
   ci.inventory_serie_id as serieinv,
   ci.item_media, ci.item_status, ci.section,
   ci.home_library_id,ci.owner_library_id,
   u.unimarc_105,
   case when
--      ( (ci.section in ('R','RN','CAA')) OR (cc.collocazione ~ ('(^R\.)|(^R )|(^RN\.)|(^RN )') ) )
        ( (ci.section in ('R','RN','CAA')) OR (cc.collocazione ~ ('^R\.|^R |^RN\.|^RN |^DVD\.R\.|^DVD\.RN\.') ) )
        OR
      ( (ci.owner_library_id=2 and ci.inventory_serie_id='RAG') )
        OR      ( u.unimarc_105 = 'r' )
     then 'ragazzi'
     else 'adulti'
   end as pubblico
   FROM clavis.item AS ci
      JOIN sbct_acquisti.library_codes lc ON(lc.clavis_library_id=ci.owner_library_id)
      LEFT JOIN clavis.collocazioni cc ON(cc.item_id=ci.item_id)
      LEFT JOIN clavis.manifestation AS cm ON(cm.manifestation_id=ci.manifestation_id)
      LEFT JOIN clavis.uni105_4 u ON(u.manifestation_id=cm.manifestation_id)
      LEFT JOIN clavis.l_authority_manifestation AS lam ON(lam.manifestation_id=cm.manifestation_id and lam.link_type=676)
      LEFT JOIN clavis.authority AS au USING(authority_id)
      WHERE ci.item_media != 'S'
      AND lc.owner='bct'
      AND owner_library_id > 0
      AND ci.item_status NOT IN ('E','H')
 ;

-- select count(*) from clavis.view_patrimonio;

select * from clavis.view_patrimonio  where manifestation_id = 121984;






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

*/

select * from view_patrimonio where manifestation_id = 269702;


create or replace view public.view_bibliobct as
  select c.label,c.owner,l.library_id,l.label as biblioteca
   from sbct_acquisti.library_codes c join
         clavis.library l on (l.library_id=c.clavis_library_id);
	 
	 
	
