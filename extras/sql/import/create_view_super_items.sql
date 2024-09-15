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

ci.inventory_number,cm.manifestation_id,cm.bib_level,cm.bib_type_first,cm.bib_type,

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


case -- per statcol

  when ci.home_library_id in(2,3) then

    case
      -- civica centrale, RAG   ATTENZIONE differenziare con occ.coll_rag not null

      when ci.home_library_id = 3 and (cc.colloc_stringa ~ E'^907\\.C\\.' OR cc.colloc_stringa ~ E'^L\\.B\\.')
                         then 'libretti_ballo'
      when ci.home_library_id = 3 and (uni105.u105_11 = 'i' OR cc.colloc_stringa ~ E'^L\\.O\\.')
                         then 'libretti'
      when ci.home_library_id = 3 and cm.bib_type = 'c01' then 'partiture musicali'
      when ci.home_library_id = 3 and cm.bib_type = 'j01' then 'dischi vinile'
      when ci.home_library_id = 3 and cm.bib_type = 'j02' then 'CD'
      when ci.home_library_id = 3 and cm.bib_type = 'j03' then 'DVD (audio)'
      when ci.home_library_id = 3 and cm.bib_type = 'g03' then 'DVD (video)'

      -- when ci.home_library_id = 3 and uni105.u105_4 = 'r' then 'ragazzi'

       -- manoscritti e rari
     when ci.home_library_id = 2 and cc.colloc_stringa ~ (E'^400\\.[A-G]|^401\\.[A-G]|^402\\.[A-G]|^403\\.[A-G]|^404\\.[A-G]|^405\\.[A-G]') then 'RARI'
     when ci.home_library_id = 2 and cc.colloc_stringa ~ (E'^407\\.[A-G]|^408\\.[A-G]|^408\\.L\\.|^408\\.[M-P]') then 'RARI'
     when ci.home_library_id = 2 and cc.colloc_stringa ~ (E'^407\\.[XA-XD]|^408\\.[XA-XD]') then 'RARI'
     when ci.home_library_id = 2 and cc.colloc_stringa ~ (E'^410\\.[A-H]|^411\\.[A-H]|^412\\.[A-H]|^413\\.[A-H]|^410\\.[XA-XD]') then 'RARI'

     when ci.home_library_id = 2 and
         (cc.primo_i between 67 and 79 and cc.secondo between 'A' and 'H')
        then 'RARI'
     
     when ci.home_library_id = 2 and cc.colloc_stringa ~* (E'^Archivio\\.|^Fer\\.|^Fot\\.|^Reg\\.') then 'RARI'
     when ci.home_library_id = 2 and cc.colloc_stringa ~* ('manos') then 'RARI'
     when ci.home_library_id = 2 and cc.colloc_stringa ~* ('ms') then 'RARI'
     when ci.home_library_id = 2 and cc.colloc_stringa ~* ('manos') then 'RARI'
     when ci.home_library_id = 2 and cc.colloc_stringa ~* ('sci') then 'RARI'
     when ci.home_library_id = 2 and cc.colloc_stringa ~* ('gioberti') then 'RARI'
     when ci.home_library_id = 2 and cc.colloc_stringa ~* (E'^tesi') then 'RARI'
     when ci.home_library_id = 2 and cc.colloc_stringa ~* (E'^coll\\.') then 'Collezioni'
     when ci.home_library_id = 2 and cc.primo_i = '303' then 'Dante'
     when ci.home_library_id = 2 and cc.primo_i between 317 and 319 then 'Teatro'
     when ci.home_library_id = 2 and cc.primo_i  between 811 and 820 then 'Kennedy'
     when ci.home_library_id = 2 and
         (cc.primo_i = 599 and cc.secondo = 'H') then 'Hoepli'


      -- multimedia centrale
      when ci.home_library_id = 2 and ci.item_media = 'R' or cc.colloc_stringa ~ '^V' then 'VHS'
      when ci.home_library_id = 2 and ci.item_media in ('A','N','M','G') then 'Audioregistrazione'
      when ci.home_library_id = 2 and cc.colloc_stringa ~ '^CD' then 'Audioregistrazione'
      when ci.home_library_id = 2 and ci.item_media = 'L' then 'Oggetto'
      when ci.home_library_id = 2 and ci.item_media = 'H' then 'Musica a Stampa'
      when ci.home_library_id = 2 and ci.item_media = 'E' then 'Microforma'
      when ci.home_library_id = 2 and ci.item_media = 'D' then 'Materiale Cartografico'
      when ci.home_library_id = 2 and ci.item_media = 'B' then 'Manoscritto'
      when ci.home_library_id = 2 and ci.item_media = 'Q' then 'DVD'
      when ci.home_library_id = 2 and cc.primo= 'DVD' then 'DVD'
      when ci.home_library_id = 2 and ci.item_media = 'T' then 'Libro Parlato'
      when ci.home_library_id = 2 and ci.item_media = 'C' then 'Grafica'
      when ci.home_library_id = 2 and cc.colloc_stringa ~* (E'^Tattili') then 'Tattili'

      -- ragazzi centrale
      -- RAG
      when ci.home_library_id = 2 and ci.section = 'CAA' then 'CAA'
      when ci.home_library_id = 2 and ci.inventory_serie_id = 'RAG' and occ.primo = 'R' and substr(occ.colloc_stringa,3,3) ~ E'^\\d{3}$'
         then 'R.' || substr(occ.colloc_stringa,3,1)::char(3) || '00'
      when ci.home_library_id = 2 and ci.inventory_serie_id = 'RAG' and occ.primo = 'RN' and occ.secondo_i  between 1 and 19 then occ.primo || '.' || occ.secondo
      when ci.home_library_id = 2 and ci.inventory_serie_id = 'RAG' and occ.primo = 'RN' and occ.terzo_i   between 1 and 19 then occ.primo || '.' || occ.terzo
      when ci.home_library_id = 2 and ci.inventory_serie_id = 'RAG' and occ.colloc_stringa is null and substr(cdd.class_code,1,3) ~ E'^\\d{3}$'
         then 'R.' || substr(cdd.class_code,1,1)::char(3) || '00'
      when ci.home_library_id = 2 and ci.inventory_serie_id = 'RAG' and occ.colloc_stringa ~ '' then 'RNonClassif'
      when ci.home_library_id = 2 and ci.inventory_serie_id = 'RAG' and occ.colloc_stringa is null  and upclass.up_class_code IS NOT NULL
         then 'R.' || substr(upclass.up_class_code,1,1) || '00'
      when ci.home_library_id = 2 and ci.inventory_serie_id = 'RAG' then 'RAG'

     -- ANTE2009 
      when ci.home_library_id = 2 and cc.colloc_stringa ~ (E'^206\\.[K-R]|^686\\.|^689\\.|^701\\.A|^701\\.B|^701\\.C|^702\\.A|^703\\.')
        and occ.primo = 'R' and substr(occ.colloc_stringa,3,3) ~ E'^\\d{3}$' then 'R.' || substr(occ.colloc_stringa,3,1)::char(3) || '00'
      when ci.home_library_id = 2 and cc.colloc_stringa ~ (E'^587\\.[A-G]|^588\\.|^589\\.|^590\\.|^591\\.|^592\\.|^593\\.|^594\\.|^595\\.|^596\\.|^597\\.')
        and occ.primo = 'R' and substr(occ.colloc_stringa,3,3) ~ E'^\\d{3}$' then 'R.' || substr(occ.colloc_stringa,3,1)::char(3) || '00'
      when ci.home_library_id = 2 and cc.colloc_stringa ~ (E'^206\\.[K-R]|^686\\.|^689\\.|^701\\.A|^701\\.B|^701\\.C|^702\\.A|^703\\.')
        and occ.primo = 'RN' and occ.secondo_i  between 1 and 19 then occ.primo || '.' || occ.secondo
      when ci.home_library_id = 2 and cc.colloc_stringa ~ (E'^587\\.[A-G]|^588\\.|^589\\.|^590\\.|^591\\.|^592\\.|^593\\.|^594\\.|^595\\.|^596\\.|^597\\.')
        and occ.primo = 'RN' and occ.secondo_i  between 1 and 19 then occ.primo || '.' || occ.secondo
      when ci.home_library_id = 2 and cc.colloc_stringa ~ (E'^206\\.[K-R]|^686\\.|^689\\.|^701\\.A|^701\\.B|^701\\.C|^702\\.A|^703\\.')
        and occ.primo = 'RN' and occ.terzo_i   between 1 and 19 then occ.primo || '.' || occ.terzo
      when ci.home_library_id = 2 and cc.colloc_stringa ~ (E'^587\\.[A-G]|^588\\.|^589\\.|^590\\.|^591\\.|^592\\.|^593\\.|^594\\.|^595\\.|^596\\.|^597\\.')
        and occ.primo = 'RN' and occ.terzo_i   between 1 and 19 then occ.primo || '.' || occ.terzo

      when ci.home_library_id = 2 and cc.colloc_stringa ~ (E'^206\\.[K-R]|^686\\.|^689\\.|^701\\.A|^701\\.B|^701\\.C|^702\\.A|^703\\.')
        and occ.colloc_stringa is null and substr(cdd.class_code,1,3) ~ E'^\\d{3}$' then 'R.' || substr(cdd.class_code,1,1)::char(3) || '00'
      when ci.home_library_id = 2 and cc.colloc_stringa ~ (E'^587\\.[A-G]|^588\\.|^589\\.|^590\\.|^591\\.|^592\\.|^593\\.|^594\\.|^595\\.|^596\\.|^597\\.')
        and occ.colloc_stringa is null and substr(cdd.class_code,1,3) ~ E'^\\d{3}$' then 'R.' || substr(cdd.class_code,1,1)::char(3) || '00'

      when ci.home_library_id = 2 and cc.colloc_stringa ~ (E'^206\\.[K-R]|^686\\.|^689\\.|^701\\.A|^701\\.B|^701\\.C|^702\\.A|^703\\.')
        and upclass.up_class_code IS NOT NULL then 'R.' || substr(upclass.up_class_code,1,1) || '00'
      when ci.home_library_id = 2 and cc.colloc_stringa ~ (E'^587\\.[A-G]|^588\\.|^589\\.|^590\\.|^591\\.|^592\\.|^593\\.|^594\\.|^595\\.|^596\\.|^597\\.')
        and upclass.up_class_code IS NOT NULL then 'R.' || substr(upclass.up_class_code,1,1) || '00'

      when ci.home_library_id = 2 and cc.colloc_stringa ~ (E'^206\\.[K-R]|^686\\.|^689\\.|^701\\.A|^701\\.B|^701\\.C|^702\\.A|^703\\.')
        and occ.colloc_stringa ~ '' then 'RNonClassif'
      when ci.home_library_id = 2 and cc.colloc_stringa ~ (E'^587\\.[A-G]|^588\\.|^589\\.|^590\\.|^591\\.|^592\\.|^593\\.|^594\\.|^595\\.|^596\\.|^597\\.')
        and occ.colloc_stringa ~ '' then 'RNonClassif'

      when ci.home_library_id = 2 and cc.colloc_stringa ~ (E'^206\\.[K-R]|^686\\.|^689\\.|^701\\.A|^701\\.B|^701\\.C|^702\\.A|^703\\.') THEN 'ante2009'
      when ci.home_library_id = 2 and cc.colloc_stringa ~ (E'^587\\.[A-G]|^588\\.|^589\\.|^590\\.|^591\\.|^592\\.|^593\\.|^594\\.|^595\\.|^596\\.|^597\\.')
           then 'ante2009'
	   
      -- adulti centrale
      when ci.home_library_id = 2 and occ.colloc_stringa is not null then 'coll_rag'
      when ci.home_library_id = 2 and cc.colloc_stringa ~* (E'^Per\\.|^P\\.G\\.|^A\\.A\\.') then 'Periodici'
      when ci.home_library_id = 2 and ci.section = 'SERA.ARA' then 'ARABI'
      when ci.home_library_id = 2 and ci.section = 'CCVT' and substr(cc.secondo,1,3) ~ E'^\\d{3}$'
         then substr(cc.secondo,1,1)::char(3) || '00'
      when ci.home_library_id = 2 and cc.colloc_stringa ~* (E'^Cons\\.P\\.') and substr(cc.colloc_stringa,8,3) ~ E'^\\d{3}$'
         then substr(cc.colloc_stringa,8,1)::char(3) || '00'
      when ci.home_library_id = 2 and cc.colloc_stringa ~* (E'^Cons\\.') and substr(cc.colloc_stringa,6,3) ~ E'^\\d{3}$'
         then substr(cc.colloc_stringa,6,1)::char(3) || '00'
      when ci.home_library_id = 2 and cc.primo = 'SAP' and substr(cc.secondo,1,3) ~ E'^\\d{3}$'
         then substr(cc.secondo,1,1)::char(3) || '00'
      when ci.home_library_id = 2 and cc.colloc_stringa ~* (E'^S\\.L\\.') and substr(cc.colloc_stringa,5,3) ~ E'^\\d{3}$'
         then substr(cc.colloc_stringa,5,1)::char(3) || '00'
      when ci.home_library_id = 2 and ci.section = 'BIBLIO' then 'BIBLIO'
      when ci.home_library_id = 2 and ci.section = 'BCT' and cc.primo_i between 1 and 58 and cc.secondo ~ E'^[A-F]' then '700'
      when ci.home_library_id = 2 and ci.section = 'BCT' and cc.primo_i between 664 and 666 then '700'
      when ci.home_library_id = 2 and ci.inventory_serie_id = 'ART' then '700'

      when ci.home_library_id = 2 and cc.colloc_stringa ~ (E'^CCNC|^CCPT') then 'Narrativa'
      when ci.home_library_id = 2 and oca.colloc_stringa ~ (E'^N') then 'Narrativa'
      when ci.home_library_id = 2 and oca.colloc_stringa ~ E'^[A-Za-z]{3,7}$' then 'Narrativa'

      when ci.home_library_id = 2 and substr(oca.colloc_stringa,1,3) ~ E'^\\d{3}$' then substr(oca.colloc_stringa,1,1)::char(3) || '00'
      when ci.home_library_id = 2 and substr(oca.colloc_stringa,3,3) ~ E'^\\d{3}$' then substr(oca.colloc_stringa,3,1)::char(3) || '00'
      when ci.home_library_id = 2 and substr(oca.colloc_stringa,4,3) ~ E'^\\d{3}$' then substr(oca.colloc_stringa,4,1)::char(3) || '00'
      when ci.home_library_id = 2 and substr(oca.colloc_stringa,5,3) ~ E'^\\d{3}$' then substr(oca.colloc_stringa,5,1)::char(3) || '00'
      when ci.home_library_id = 2 and cdd.class_code IS NOT NULL then substr(cdd.class_code,1,1) || '00'
      when ci.home_library_id = 2 and upclass.up_class_code IS NOT NULL then substr(upclass.up_class_code,1,1) || '00'

      else 'da assegnare'
    end

  else -- tutte le NON 2,3
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
    when cc.colloc_stringa ~ '^N' then 'Narrativa'

    when ci.section = 'BCT' and collocation ~ E'^[A-Za-z]{3,7}$' then 'Narrativa'

    when cle.label is not null then cc.primo || '.' || cc.terzo

    -- when cc.primo = 'RN' and cc.terzo_i    between 1 and 19 then cc.primo || '.' || cc.terzo
    when cc.primo = 'RN' and cc.secondo_i  between 1 and 19 then cc.primo || '.' || cc.secondo
--modifica
    when cc.primo = 'RN' and cc.terzo_i   between 1 and 19 then cc.primo || '.' || cc.terzo
    --when occ.primo = 'RN' and occ.secondo_i between 1 and 19 then occ.primo || '.' || occ.secondo


--rimettere a posto
    --when occ.primo = 'RN' and occ.terzo_i   between 1 and 19 then occ.primo || '.' || occ.terzo
    --when occ.primo = 'RN' and occ.secondo_i between 1 and 19 then occ.primo || '.' || occ.secondo

    when substr(cc.colloc_stringa,1,3) ~ E'^\\d{3}$'
      then substr(cc.colloc_stringa,1,1)::char(3) || '00'

    -- es. C.035 oppure P.150
    when cc.primo in ('C','P')  and substr(cc.colloc_stringa,3,3) ~ E'^\\d{3}$'
      then substr(cc.colloc_stringa,3,1)::char(3) || '00'
    -- es PC.560.DIR 
    when cc.primo = 'PC' and substr(cc.colloc_stringa,4,3) ~ E'^\\d{3}$'
      then substr(cc.colloc_stringa,4,1)::char(3) || '00'

    -- es P.C.560.DIR
    when cc.primo = 'P.C.' and substr(cc.colloc_stringa,5,3) ~ E'^\\d{3}$'
      then substr(cc.colloc_stringa,5,1)::char(3) || '00'
 
    when cc.primo = 'R' and substr(cc.colloc_stringa,3,3) ~ E'^\\d{3}$'
      then 'R.' || substr(cc.colloc_stringa,3,1)::char(3) || '00'

    when cc.primo = 'RC' and substr(cc.colloc_stringa,4,3) ~ E'^\\d{3}$'
      then 'R.' || substr(cc.colloc_stringa,4,1)::char(3) || '00'

    -- R.C.035 che deve andare in R.000
    when cc.colloc_stringa ~ E'^R\\.C\\.' and substr(cc.colloc_stringa,5,3) ~ E'^\\d{3}$'
      then 'R.' || substr(cc.colloc_stringa,5,1)::char(3) || '00'

     when cc.primo = 'R' and cdd.class_code IS NULL
         then cc.primo || '.' || substr(cc.secondo,1,1) || '00'

    when cc.primo = 'R' and cdd.class_code IS NOT NULL
       then cc.primo || '.' || substr(cdd.class_code,1,1) || '00'

    else 'NonClassif'
  end

end as statcol,

   oca.colloc_stringa as coll_adu,
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
   case when uni105.u105_4  != '' then uni105.u105_4 end as u105_4,
   case when uni105.u105_11 != '' then uni105.u105_11 end as u105_11,
   case when uni105.u100_pubblico != '' then uni105.u100_pubblico end as u100_pubblico,

  case
    when ci.home_library_id in(2,3) then
      case
        when ci.inventory_serie_id = 'RAG' then 'ragazzi' -- NB serie RAG è solo Centrale (non serve filtro per biblioteca)
	when ci.home_library_id = '3' and uni105.u105_4 = 'r' then 'ragazzi'
	when ci.home_library_id = '2' and cc.colloc_stringa ~ (E'^206\\.[K-R]|^686\\.|^689\\.|^701\\.A|^701\\.B|^701\\.C|^702\\.A|^703\\.') then 'ragazzi'
	when ci.home_library_id = '2' and cc.colloc_stringa ~ (E'^587\\.[A-G]|^588\\.|^589\\.|^590\\.|^591\\.|^592\\.|^593\\.|^594\\.|^595\\.|^596\\.|^597\\.')
	  then 'ragazzi'
        else 'adulti'
      end
    else -- Tutte le non 2,3
      case when
        ( (ci.section in ('R','RN','CAA')) OR (cc.colloc_stringa ~ (E'^R\\.|^RC\\.|^RN\\.|^DVD\\.791\\.433\\.| ^DVD\\.791\\.4334\\.|^DVD\\.R\\.|^DVD\\.RN\\.|
                                                                      ^CD\\.R\\.|^CD\\.RN\\.|^MCD\\.7|^MC\\.7') ) )
        then 'ragazzi'
      else 'adulti'
    end
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
    when ci.home_library_id in(2,3) then

    case
    when ci.home_library_id = 2 and ci.item_media in ('R','A','N','M','G','L','E','Q','T') THEN 'multimedia'
    when ci.home_library_id = 2 and ci.section in ('CCNC','CCPT') then 'vol_narrativa'
    when ci.home_library_id = 2 and oca.colloc_stringa ~ (E'^N') then 'vol_narrativa'
    when ci.home_library_id = 2 and ci.inventory_serie_id = 'RAG' and occ.primo = 'RN' and occ.secondo_i  between 1 and 19 then 'vol_narrativa'
    when ci.home_library_id = 2 and ci.inventory_serie_id = 'RAG' and occ.primo = 'RN' and occ.terzo_i   between 1 and 19 then 'vol_narrativa'
    when ci.home_library_id = 2 and cc.colloc_stringa ~ (E'^206\\.[K-R]|^686\\.|^689\\.|^701\\.A|^701\\.B|^701\\.C|^702\\.A|^703\\.')
        and occ.primo = 'RN' and occ.secondo_i  between 1 and 19 then 'vol_narrativa'
    when ci.home_library_id = 2 and cc.colloc_stringa ~ (E'^587\\.[A-G]|^588\\.|^589\\.|^590\\.|^591\\.|^592\\.|^593\\.|^594\\.|^595\\.|^596\\.|^597\\.')
        and occ.primo = 'RN' and occ.secondo_i  between 1 and 19 then 'vol_narrativa'
    when ci.home_library_id = 2 and cc.colloc_stringa ~ (E'^206\\.[K-R]|^686\\.|^689\\.|^701\\.A|^701\\.B|^701\\.C|^702\\.A|^703\\.')
        and occ.primo = 'RN' and occ.terzo_i   between 1 and 19 then 'vol_narrativa'
    when ci.home_library_id = 2 and cc.colloc_stringa ~ (E'^587\\.[A-G]|^588\\.|^589\\.|^590\\.|^591\\.|^592\\.|^593\\.|^594\\.|^595\\.|^596\\.|^597\\.')
        and occ.primo = 'RN' and occ.terzo_i   between 1 and 19 then 'vol_narrativa'
    else 'vol_saggistica'
  end
else
  case
    when ci.item_media = 'A' or cc.colloc_stringa ~ (E'^MCD\\.|^MC\\.')  or cc.primo = 'CD' then 'multimedia'
    when cc.colloc_stringa ~ E'^MCD\\.9'  then 'multimedia'
    when ci.item_media = 'T' then 'multimedia'
    when ci.item_media = 'Q' or cc.primo= 'DVD' then 'multimedia'
    when ci.item_media = 'R' or cc.colloc_stringa ~ '^V' then 'multimedia'

    when (ci.section in ('RN','N','NG','NR','NF')) OR (cc.colloc_stringa ~ (E'^RN|^R\\.N|^N') )
        then 'vol_narrativa'
    when ci.section = 'BCT' and collocation ~ E'^[A-Za-z]{3,7}$' then 'vol_narrativa'

    else 'vol_saggistica'
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
   end as alt_genere,

   cle.label as codice_lingua


   FROM item AS ci
    LEFT JOIN sbct_acquisti.library_codes lc1 ON(lc1.clavis_library_id=ci.home_library_id  and lc1.owner='bct')

    LEFT JOIN sbct_acquisti.library_codes lc2 ON(lc2.clavis_library_id=ci.owner_library_id)
    
      LEFT JOIN collocazioni AS  cc ON(cc.item_id=ci.item_id)
      LEFT JOIN manifestation AS cm ON(cm.manifestation_id=ci.manifestation_id and cm.bib_level='m')
      LEFT JOIN uni105 ON(uni105.manifestation_id=cm.manifestation_id)  -- Vedi http://unimarc-it.wikidot.com/105 sottocampi 4 e 11

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

   --prova
   LEFT JOIN LATERAL
        (SELECT xc.colloc_stringa,oci.home_library_id,xc.primo,xc.secondo,xc.terzo,xc.secondo_i,xc.terzo_i,xc.item_id
        FROM item AS oci JOIN collocazioni AS xc using(item_id)
           JOIN sbct_acquisti.library_codes ON(clavis_library_id=oci.home_library_id AND owner='bct')
         WHERE oci.manifestation_id = cm.manifestation_id and oci.home_library_id!=ci.home_library_id
            AND oci.item_status != 'E' and xc.primo not in ('CLA','SAL','Collina') and oci.home_library_id != '3'
            AND oci.item_id != ci.item_id and ci.owner_library_id>0 limit 1) as oca on true
--fine prova


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


--select item_id,manifestation_id,statcol,colloc_stringa,home_library from view_super_items where manifestation_id
  --  in(93460,761211,642909,268164,180303,541278);


-- select item_id,manifestation_id,statcol,colloc_stringa,home_library from view_super_items where statcol='RARI';
