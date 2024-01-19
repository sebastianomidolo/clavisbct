-- Viste nuove create in gennaio 2024


-- NB: non dovrebbe esistere manifestation con id 0:
delete from clavis.manifestation where manifestation_id=0;


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
   ci.item_media, ci.section,
   ci.home_library_id,ci.owner_library_id,
   case when
      ( (ci.section in ('R','RN')) OR (cc.collocazione ~ ('^(R\.)|(R )') ) )
        OR
      ( (ci.owner_library_id=2 and ci.inventory_serie_id='RAG') )
     then 'ragazzi'
     else 'adulti'
   end as pubblico
   FROM clavis.item AS ci
      JOIN sbct_acquisti.library_codes lc ON(lc.clavis_library_id=ci.owner_library_id)
      LEFT JOIN clavis.collocazioni cc ON(cc.item_id=ci.item_id)
      LEFT JOIN clavis.manifestation AS cm ON(cm.manifestation_id=ci.manifestation_id)
      LEFT JOIN clavis.l_authority_manifestation AS lam ON(lam.manifestation_id=cm.manifestation_id and lam.link_type=676)
      LEFT JOIN clavis.authority AS au USING(authority_id)
      WHERE ci.item_media != 'S'
      AND lc.owner='bct'
      AND owner_library_id > 0
      AND ci.item_status NOT IN ('E','H')
      -- AND au.class_code is not null
 ;

select * from clavis.view_patrimonio where class_code is null limit 10;
-- select count(*) from clavis.view_patrimonio;

select * from clavis.view_patrimonio  where manifestation_id = 121984;






