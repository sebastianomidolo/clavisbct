\pset tuples_only t
\pset border 0
\pset pager f

SELECT '<?xml version="1.0" encoding="UTF-8"?>';
SELECT xmlcomment('inizio esportazione: ' || now());
select '<dataroot xmlns:od="urn:schemas-microsoft-com:officedata" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="TabFonoteca.xsd" generated="' || now() || '">';
select xmlelement(
 name "TabFonoteca",
  xmlattributes(cm.manifestation_id as opac_id, a.idvolume as bm_id, a.tipologia),
  xmlconcat(
   xmlelement(name titolo,
       CASE WHEN cm.title is null THEN
           -- a.titolo || ' - ' || a.autore || ' - ' || a.interpreti
           a.titolo
       ELSE trim(cm.title)
       END
   ),
   CASE WHEN a.autore is not null THEN
     xmlelement(name autore, a.autore)
   END,
   CASE WHEN a.interpreti is not null THEN
     xmlelement(name interpreti, a.interpreti)
   END,
   xmlelement(name collocazione,
    CASE WHEN ci.collocation is null THEN replace(collocazione,' ','') ELSE ci.collocation END))
  )
 from bm_audiovisivi.t_volumi a left
join av_manifestations av using(idvolume) left join clavis.item ci
on(av.manifestation_id=ci.manifestation_id) left join clavis.manifestation cm
on(ci.manifestation_id=cm.manifestation_id)
where a.collocazione is not null
-- and a.idvolume=41
-- limit 2
;select '</dataroot>';
SELECT xmlcomment('fine importazione: ' || now());
