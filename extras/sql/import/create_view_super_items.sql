
SET SEARCH_PATH TO import;

set standard_conforming_strings to false;
set backslash_quote to 'safe_encoding';

DROP VIEW IF EXISTS view_super_items CASCADE;
CREATE OR REPLACE VIEW view_super_items as

SELECT
trim(ci.title) as title, ci.item_id, ci.barcode, cm.edition_date,

case when ci.reprint != '' then ci.reprint end as reprint,

case when ci.reprint ~ E'^\\d{4}' then substr(ci.reprint,1,4)::integer end as reprint_year,

case when ci.reprint ~ E'^\\d{4}' and substr(ci.reprint,1,4)::integer > cm.edition_date then
 substr(ci.reprint,1,4)::integer else
 case
   when cm.edition_date is not null then cm.edition_date
    else case when ci.reprint ~ E'^\\d{4}' then substr(ci.reprint,1,4)::integer end end
end as print_year,

-- case when ci.owner_library_id = -1 then -ci.item_id else ci.item_id end as item_id,
-- case when ci.owner_library_id = -1 then ci.custom_field3 end as topogr_id,

case when ci.inventory_serie_id != '' then ci.inventory_serie_id end as inventory_serie_id,

ci.inventory_number,cm.manifestation_id,cm.bib_level,cm.bib_type,

-- case when ci.inventory_date is null then ci.date_created else ci.inventory_date end as inventory_date,

ci.date_created, ci.inventory_date,

-- cdd.link_type,cdd.authority_id,
cdd.class_code,upclass.up_class_code,ci.date_discarded,
cc.primo as primo_elemento_collocazione,

loans_info.*,
loans_info_totale.*,
otlib.*,
last_loans.loan_date_begin as ultimo_prestito,

case when cm is not null or ci.opac_visible=1 then false else true end as opac_invisible,

case when
   not cc.colloc_stringa ~ E'^P\\.G\\.'
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
 when ci.loan_class = 'F'
     or cc.colloc_stringa ~ (E'^Cons\\.|^C\\.')
     or cc.colloc_stringa ~ (E'^RC|^R\\.C|^RNC|^RN\\.C')
     or (cc.colloc_stringa ~ E'^P\\.C\\.' and ci.home_library_id not in (2,3))
then true else false end as consultazione,

case
  when lc1 is null then null
  when cc.colloc_stringa ~ (E'^RN|^R\\.N|^N|^CCNC|^CCPT') then 'N'
  when ci.home_library_id not in (2,3) and substr(cc.colloc_stringa,1,3) ~ E'^\\d{3}$'
    then substr(cc.colloc_stringa,1,3)::char(3)
  when cdd.class_code is not null then substr(cdd.class_code,1,3)::char(3)
  when upclass.up_class_code is not null then substr(upclass.up_class_code,1,3)::char(3)
  else 'nc'
end as dw3,

case -- per statcol
  when cm.bib_type='i02' then 'CDi02'
  when cm.bib_type='j02' then 'CDj02'
  when ci.item_media = 'A' then 'Audiovisivi'
  when ci.item_media = 'T' then 'Libri parlati'
  when ci.item_media = 'Q' then 'DVD'
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

   cc.colloc_stringa as colloc_stringa, ci.collocation as colloc_clavis, occ.colloc_stringa as coll_rag, occ.home_library_id as coll_rag_library_id,
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
     ( (ci.section in ('R','RN','CAA')) OR (cc.colloc_stringa ~ (E'^R\\.|^RN\\.|^DVD\\.R\\.|^DVD\\.RN\\.') ) )
        OR
     ( (ci.owner_library_id=2 and ci.inventory_serie_id='RAG') )
        OR      ( u.unimarc_105 = 'r' AND NOT cc.colloc_stringa ~ (E'^N\\.|^NF\\.|^NG\\.'))
     then 'ragazzi'
     else 'adulti'
   end as pubblico,

   case
     when ci.item_media IN ('A', 'Q') then NULL
     when cc.colloc_stringa ~ (E'^Cons\\.|^RC\\.|^RC ') then NULL
     else
      case
       when (ci.section in ('RN','CCNC','N','NG')) OR (cc.colloc_stringa ~ (E'^RN|^R\\.N|^N') )
        then 'narrativa'
        else 'saggistica'
     end
   end as genere,

/*
test:
select item_id,colloc_stringa,genere,alt_genere from view_super_items where alt_genere ~ '^errato' limit 100;
*/
   case
     when ci.item_media IN ('A', 'Q') then NULL
     when cc.colloc_stringa ~ (E'^Cons\\.|^RC\\.|^RC ') then NULL
     else
      case
       when cc.primo = 'R'  and cc.secondo ~ E'^\\d{2}$' then 'errato (2 cifre invece di 3)'
       when cc.primo = 'RN' and cc.secondo ~ E'^\\d{3}$' then 'errato (3 cifre invece di 2)'
       when (ci.section in ('RN','CCNC','N','NG')) OR (cc.colloc_stringa ~ (E'^RN|^R\\.N|^N') )
         then 'narrativa'
         else 'saggistica'
      end
   end as alt_genere


   FROM item AS ci
    LEFT JOIN sbct_acquisti.library_codes lc1 ON(lc1.clavis_library_id=ci.home_library_id  and lc1.owner='bct')

    LEFT JOIN sbct_acquisti.library_codes lc2 ON(lc2.clavis_library_id=ci.owner_library_id)
    
      LEFT JOIN collocazioni AS  cc ON(cc.item_id=ci.item_id)
      LEFT JOIN manifestation AS cm ON(cm.manifestation_id=ci.manifestation_id and cm.bib_level='m')
      LEFT JOIN uni105_4 u ON(u.manifestation_id=cm.manifestation_id)

      LEFT JOIN lookup_value lv1 on(lv1.value_key=ci.item_media  AND lv1.value_language = 'it_IT' AND lv1.value_class = 'ITEMMEDIATYPE')
      LEFT JOIN lookup_value lv2 on(lv2.value_key=ci.item_status AND lv2.value_language = 'it_IT' AND lv2.value_class = 'ITEMSTATUS')
      LEFT JOIN lookup_value lv3 on(lv3.value_key=ci.loan_class AND lv3.value_language = 'it_IT' AND lv3.value_class = 'LOANCLASS')

   LEFT JOIN LATERAL
     (SELECT lam.link_type, au.authority_id, regexp_replace(au.class_code, E'\\s|\\t', '', 'g') as class_code
       FROM l_authority_manifestation AS lam
       LEFT JOIN authority AS au USING(authority_id)
        WHERE lam.manifestation_id=cm.manifestation_id and lam.link_type=676
       order by class_code limit 1) as cdd on true

     LEFT JOIN LATERAL
        (SELECT xc.colloc_stringa,oci.home_library_id,xc.primo,xc.secondo,xc.terzo,xc.secondo_i,xc.terzo_i,xc.item_id
        FROM item AS oci JOIN collocazioni AS xc using(item_id)
           JOIN sbct_acquisti.library_codes ON(clavis_library_id=oci.home_library_id AND owner='bct')
	 WHERE oci.manifestation_id = cm.manifestation_id and oci.home_library_id!=ci.home_library_id
	    AND xc.colloc_stringa ~ '^R' AND oci.item_status != 'E'
	    AND oci.item_id != ci.item_id and ci.owner_library_id>0 limit 1) as occ on true


     LEFT JOIN LATERAL
     (SELECT lam.link_type as up_link_type, au.authority_id as up_authority_id, regexp_replace(au.class_code, E'\\s|\\t', '', 'g') as up_class_code
        FROM l_manifestation clm
	   LEFT JOIN l_authority_manifestation AS lam ON (lam.manifestation_id=clm.manifestation_id_down)
          LEFT JOIN authority AS au USING(authority_id)
        WHERE lam.manifestation_id=clm.manifestation_id_down and lam.link_type=676
           and manifestation_id_up = cm.manifestation_id AND clm.link_type = 461
       order by class_code limit 1) as upclass on true


  LEFT JOIN LATERAL
    (select count(*) as prestiti, array_to_string(array_agg(DISTINCT date_part('year', cl.loan_date_begin)
       ORDER BY date_part('year', cl.loan_date_begin)), ',') as anni_prestito
     FROM loan cl WHERE cl.item_id=ci.item_id) as loans_info on true

  LEFT JOIN LATERAL
    (select count(*) as prestiti_totale, array_to_string(array_agg(DISTINCT date_part('year', cl.loan_date_begin)
       ORDER BY date_part('year', cl.loan_date_begin)), ',') as anni_prestito_totale
     FROM loan cl WHERE cl.manifestation_id = cm.manifestation_id ) as loans_info_totale on true

  LEFT JOIN LATERAL
    (
     select
       array_agg(DISTINCT library_codes.label) as other_library_labels,
       array_agg(DISTINCT oci.home_library_id) as other_library_ids,
       count(DISTINCT oci.home_library_id) as other_library_count
       FROM item AS oci LEFT JOIN sbct_acquisti.library_codes
         -- ON(clavis_library_id=oci.home_library_id AND owner='bct')
            ON(clavis_library_id=oci.home_library_id)
	 WHERE oci.manifestation_id = cm.manifestation_id and oci.home_library_id!=ci.home_library_id
	    AND oci.item_status != 'E'
	    AND oci.item_id != ci.item_id) as otlib on true


   LEFT JOIN LATERAL
     (SELECT cl.loan_date_begin FROM loan cl WHERE cl.item_id=ci.item_id
        and cl.loan_date_begin is not null
       order by cl.loan_date_begin desc limit 1) as last_loans on true

      WHERE ci.item_media != 'S' AND ci.item_status != 'E';
      
