
SET SEARCH_PATH TO import;

set standard_conforming_strings to false;
set backslash_quote to 'safe_encoding';

DROP VIEW IF EXISTS view_super_items CASCADE;
CREATE OR REPLACE VIEW view_super_items as

SELECT
trim(ci.title) as title, ci.item_id, ci.barcode, cm.edition_date,

case when ci.reprint != '' then ci.reprint end as reprint,

case when ci.reprint ~ E'^\\d{4}' then substr(ci.reprint,1,4)::integer end as reprint_year,

case
 when ci.reprint ~ E'^\\d{4}' and substr(ci.reprint,1,4)::integer > cm.edition_date then substr(ci.reprint,1,4)::integer
 when cm.manifestation_id is null then coalesce(date_part('year', ci.inventory_date), date_part('year', ci.date_created))
 else
 case
   -- when cm.edition_date is not null then cm.edition_date
   -- when cm.edition_date::text ~ E'^\\d{4}' then cm.edition_date::integer
   when cm.edition_date >= 1000 then cm.edition_date
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
    or  cc.primo IN ('P','PC','CCPT','Collina')
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
     or cc.colloc_stringa ~ (E'^Cons\\.|^C\\.|^Collina\\.')
     or cc.colloc_stringa ~ (E'^RC|^R\\.C|^RNC|^RN\\.C')
     or (cc.colloc_stringa ~ E'^P\\.C\\.' and ci.home_library_id not in (2,3))
     or ci.inventory_serie_id in ('SAL', 'CLA')

then true else false end as consultazione,

case
  when lc1 is null then null
  when cm.manifestation_id is null then 'fc'
  when ci.item_media = 'Q' or cc.primo = 'DVD' then 'DVD'
  -- Voce Parlata (audiolibri)
  when cc.colloc_stringa ~ E'^MCD\\.9'  then 'V_Parlata'
-- Audioregistrazione AR CD/MCD/MC                                                                              
  when ci.item_media = 'A' or cc.colloc_stringa ~ (E'^MCD\\.|^MC\\.') or cc.primo = 'CD'  then 'AR'
-- tattili
  when cc.secondo = 'Tattili' then cc.secondo
-- libri parlati
  when ci.item_media = 'T' then 'LP'
-- vhs
  when ci.item_media = 'R' or cc.colloc_stringa ~ '^V' then 'VHS'
-- BNV testo in braille
  when ci.inventory_serie_id = 'BNV' then 'Braille'
-- fondo SAL e CLA
  when ci.inventory_serie_id in ('SAL','CLA') then 'Conserv'
  
  when cc.colloc_stringa ~ (E'^RN|^R\\.N|^N|^CCNC|^CCPT') then 'N'
  when ci.section = 'BCT' and collocation ~ E'^[A-Za-z]{3,7}$' then 'N'
  when ci.section = 'CAA' then 'CAA'

-- Lorusso e Cotugno sezione SERA.ARA
  when ci.section = 'SERA.ARA' then 'SERA'
-- Primo elemento = collina
  when cc.primo = 'Collina'  and substr(cc.colloc_stringa,9,3) ~ E'^\\d{3}$'
    then substr(cc.colloc_stringa,9,3)::char(3)


  when ci.home_library_id not in (2,3) and substr(cc.colloc_stringa,1,3) ~ E'^\\d{3}$'
    then substr(cc.colloc_stringa,1,3)::char(3)

  when ci.home_library_id not in (2,3) and cc.primo in ('R','P','C') and substr(cc.colloc_stringa,3,3) ~ E'^\\d{3}$'
    then substr(cc.colloc_stringa,3,3)::char(3)

  when ci.home_library_id not in (2,3) and cc.primo in ('PC','RC') and substr(cc.colloc_stringa,4,3) ~ E'^\\d{3}$'
    then substr(cc.colloc_stringa,4,3)::char(3)
-- R.C. che finiscono in dw3 nc
  when cc.colloc_stringa ~ E'^R\\.C\\.' and substr(cc.colloc_stringa,5,3) ~ E'^\\d{3}$'
    then substr(cc.colloc_stringa,5,3)::char(3)

  when cdd.class_code is not null then substr(cdd.class_code,1,3)::char(3)
  when upclass.up_class_code is not null then substr(upclass.up_class_code,1,3)::char(3)
  else 'nc'
end as dw3,


--case
--  when ci.item_media IN ('A','E','G','L','M','N','Q','R','T') OR cc.colloc_stringa ~ (E'DVD') then 'Multimedia'
--  else 'Volumi'
--end as xxx,


case -- per statcol_old (vecchia versione)
  when cm.bib_type='i02' then 'CDi02'
  when cm.bib_type='j02' then 'CDj02'
  when ci.item_media = 'A' then 'CD'
  when ci.section = 'CAA' then 'CAA'
  when ci.item_media = 'T' then 'Libri parlati'
  when ci.item_media = 'Q' then 'DVD'
  else
  case
    when cc.primo not in ('RN','R','RC') then
      case
        when cc.primo IN ('CCNC','N') then 'Narrativa'
-- dorina bct wood then 'Narrativa'
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
end as statcol_old,

case -- per statcol

  -- civica centrale, RAG   ATTENZIONE differenziare con occ.coll_rag not null

  when ci.home_library_id in(2,3) then
    case
      when ci.home_library_id = 2 and ci.inventory_serie_id = 'RAG' then 'RAG'
      when cdd.class_code IS NOT NULL then substr(cdd.class_code,1,1) || '00'
      when upclass.up_class_code IS NOT NULL then substr(upclass.up_class_code,1,1) || '00'
      -- [segue tutta la casistica per 2 e 3]
      -- a titolo di esempio (non so se si vada così nell'analitico):
      when ci.home_library_id = 3 and (cc.colloc_stringa ~ E'^907\\.C\\.' OR cc.colloc_stringa ~ E'^L\\.B\\.')
                         then 'libretti_ballo'
      when ci.home_library_id = 3 and (u11.unimarc_105='i' OR cc.colloc_stringa ~ E'^L\\.O\\.')
                         then 'libretti'
      else '2,3 non assegnati'
    end

  else -- tutte le NON 2,3 (ricordarsi di indentare tutto il blocco seguente)
  case
  -- Voce parlata
  when cc.colloc_stringa ~ E'^MCD\\.9'  then 'Voce Parlata'

  when ci.item_media = 'A' or cc.colloc_stringa ~ (E'^MCD\\.|^MC\\.')  or cc.primo = 'CD' then 'Audioregistrazione'
  when ci.section = 'CAA' then 'CAA'
  when ci.item_media = 'T' then 'Libri parlati'
  when ci.item_media = 'Q' or cc.primo= 'DVD' then 'DVD'
  -- item media R= VHS o inizia per V. o VP.
  when ci.item_media = 'R' or cc.colloc_stringa ~ '^V' then 'VHS'
  when cc.secondo = 'Tattili' then cc.secondo
 -- testo in braille
  when ci.inventory_serie_id = 'BNV' then 'Braille'
 -- fondo SAL e CLA
  when ci.inventory_serie_id in ('SAL','CLA') then 'Conservazione'
  -- Lorusso e cotugno sezione SERA.ARA
  when ci.section = 'SERA.ARA' and cdd.class_code IS NOT NULL then substr(cdd.class_code,1,1) || '00'
  -- Primo Elemento Collocazione = Collina
  when cc.primo = 'Collina' and substr(cc.colloc_stringa,9,3) ~ E'^\\d{3}$'
    then substr(cc.colloc_stringa,9,1)::char(3) || '00'

  when cc.colloc_stringa ~ '^NF' then 'Narrativa NF'
  when cc.colloc_stringa ~ '^NG' then 'Narrativa NG'
  when cc.colloc_stringa ~ '^NR' then 'Narrativa NR'
  when cc.colloc_stringa ~ (E'^N|^CCNC|^CCPT') then 'Narrativa'

  when ci.section = 'BCT' and collocation ~ E'^[A-Za-z]{3,7}$' then 'Narrativa'

  when cle.label is not null then cc.primo || '.' || cc.terzo

  -- when cc.primo = 'RN' and cc.terzo_i    between 1 and 19 then cc.primo || '.' || cc.terzo
  when cc.primo = 'RN' and cc.secondo_i  between 1 and 19 then cc.primo || '.' || cc.secondo


  when ci.home_library_id in (2,3) and occ.primo = 'RN' and occ.terzo_i   between 1 and 19 then occ.primo || '.' || occ.terzo
  when ci.home_library_id in (2,3) and occ.primo = 'RN' and occ.secondo_i between 1 and 19 then occ.primo || '.' || occ.secondo

  when ci.home_library_id not in (2,3) and substr(cc.colloc_stringa,1,3) ~ E'^\\d{3}$'
    then substr(cc.colloc_stringa,1,1)::char(3) || '00'

-- proposta es. C.035 oppure P.150
  when ci.home_library_id not in (2,3) and cc.primo in ('C','P')  and substr(cc.colloc_stringa,3,3) ~ E'^\\d{3}$'
    then substr(cc.colloc_stringa,3,1)::char(3) || '00'

--proposta es PC.560.DIR 
  when ci.home_library_id not in (2,3) and cc.primo = 'PC' and substr(cc.colloc_stringa,4,3) ~ E'^\\d{3}$'
    then substr(cc.colloc_stringa,4,1)::char(3) || '00'

--proposta es P.C.560.DIR
  when ci.home_library_id not in (2,3) and cc.primo = 'P.C.' and substr(cc.colloc_stringa,5,3) ~ E'^\\d{3}$'
    then substr(cc.colloc_stringa,5,1)::char(3) || '00'


 -- fine proposta

  when ci.home_library_id not in (2,3) and cc.primo = 'R' and substr(cc.colloc_stringa,3,3) ~ E'^\\d{3}$'
    then 'R.' || substr(cc.colloc_stringa,3,1)::char(3) || '00'

  when ci.home_library_id not in (2,3) and cc.primo = 'RC' and substr(cc.colloc_stringa,4,3) ~ E'^\\d{3}$'
    then 'R.' || substr(cc.colloc_stringa,4,1)::char(3) || '00'

-- R.C.035 che deve andare in R.000                                                                                                                                                             
  when ci.home_library_id not in (2,3) and cc.colloc_stringa ~ E'^R\\.C\\.' and substr(cc.colloc_stringa,5,3) ~ E'^\\d{3}$'
    then 'R.' || substr(cc.colloc_stringa,5,1)::char(3) || '00'


  when ci.owner_library_id=2 and (ci.inventory_serie_id='RAG' OR u.unimarc_105 = 'r')
       and occ.primo = 'R' and cdd.class_code IS NULL
            then occ.primo || '.' || substr(occ.secondo,1,1) || '00'

  when ci.owner_library_id=2 and (ci.inventory_serie_id='RAG' OR u.unimarc_105 = 'r')
       and occ.primo = 'R'
            then occ.primo || '.' || substr(cdd.class_code,1,1) || '00'

--  when cdd.class_code IS NOT NULL then substr(cdd.class_code,1,1) || '00'
--  when upclass.up_class_code IS NOT NULL then substr(upclass.up_class_code,1,1) || '00'


  when cc.primo = 'R' and cdd.class_code IS NULL
       then cc.primo || '.' || substr(cc.secondo,1,1) || '00'

  when cc.primo = 'R' and cdd.class_code IS NOT NULL
     then cc.primo || '.' || substr(cdd.class_code,1,1) || '00'

  else 'NonClassif'
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
   u11.unimarc_105 as unimarc_105_11,
   case when
     ( (ci.section in ('R','RN','CAA')) OR (cc.colloc_stringa ~ (E'^R\\.|^RC\\.|^RN\\.|^DVD\\.R\\.|^DVD\\.RN\\.|^CD\\.R\\.|^CD\\.RN\\.|^MCD\\.7') ) )
        OR
     ( (ci.owner_library_id=2 and ci.inventory_serie_id='RAG') )
--        OR      ( u.unimarc_105 = 'r' AND NOT cc.colloc_stringa ~ (E'^N\\.|^NF\\.|^NG\\.'))
     then 'ragazzi'
     else 'adulti'
   end as pubblico,


case
     when ci.item_media IN ('A','E','G','L','M','N','Q','R','T') OR cc.colloc_stringa ~ (E'DVD') then 'Multimedia'
     when (ci.section in ('RN','CCNC','N','NG')) OR (cc.colloc_stringa ~ (E'^RN|^R\\.N|^N') )
        then 'Volumi Narrativa'
     when ci.section = 'BCT' and collocation ~ E'^[A-Za-z]{3,7}$' then 'Volumi Narrativa'

   else 'Volumi Saggistica'
 end as xxx,


  case
-- multimedia
    when ci.item_media = 'A' or cc.colloc_stringa ~ (E'^MCD\\.|^MC\\.')  or cc.primo = 'CD' then 'multimedia'
    when cc.colloc_stringa ~ E'^MCD\\.9'  then 'multimedia'
    when ci.item_media = 'T' then 'multimedia'
    when ci.item_media = 'Q' or cc.primo= 'DVD' then 'multimedia'
    when ci.item_media = 'R' or cc.colloc_stringa ~ '^V' then 'multimedia'

    when (ci.section in ('RN','CCNC','N','NG','NR','NF','CCPT')) OR (cc.colloc_stringa ~ (E'^RN|^R\\.N|^N') )
        then 'vol_narrativa'
    when ci.section = 'BCT' and collocation ~ E'^[A-Za-z]{3,7}$' then 'vol_narrativa'

    else 'vol_saggistica'
     
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
   end as alt_genere,

   cle.label as codice_lingua


   FROM item AS ci
    LEFT JOIN sbct_acquisti.library_codes lc1 ON(lc1.clavis_library_id=ci.home_library_id  and lc1.owner='bct')

    LEFT JOIN sbct_acquisti.library_codes lc2 ON(lc2.clavis_library_id=ci.owner_library_id)
    
      LEFT JOIN collocazioni AS  cc ON(cc.item_id=ci.item_id)
      LEFT JOIN manifestation AS cm ON(cm.manifestation_id=ci.manifestation_id and cm.bib_level='m')
      LEFT JOIN uni105_4 u ON(u.manifestation_id=cm.manifestation_id)
      LEFT JOIN uni105_11 u11 ON(u11.manifestation_id=cm.manifestation_id)  -- Vedi http://unimarc-it.wikidot.com/105 sottocampo 11

      LEFT JOIN lookup_value lv1 on(lv1.value_key=ci.item_media  AND lv1.value_language = 'it_IT' AND lv1.value_class = 'ITEMMEDIATYPE')
      LEFT JOIN lookup_value lv2 on(lv2.value_key=ci.item_status AND lv2.value_language = 'it_IT' AND lv2.value_class = 'ITEMSTATUS')
      LEFT JOIN lookup_value lv3 on(lv3.value_key=ci.loan_class AND lv3.value_language = 'it_IT' AND lv3.value_class = 'LOANCLASS')

      LEFT JOIN stats.codici_lingua_esemplari cle ON (cle.label = cc.secondo and cc.primo = 'RN')
      
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
	    -- includere: B,F,G,K,R,S,V,Y
	    -- Valutare se includere S
	    AND oci.item_id != ci.item_id) as otlib on true


   LEFT JOIN LATERAL
     (SELECT cl.loan_date_begin FROM loan cl WHERE cl.item_id=ci.item_id
        and cl.loan_date_begin is not null
       order by cl.loan_date_begin desc limit 1) as last_loans on true

      WHERE ci.item_media != 'S' AND ci.item_status != 'E';
      
