\pset tuples_only t
\pset border 0
\pset pager f


SELECT xmlcomment('inizio esportazione: ' || now());

select '<root>';
select xmlelement(
 name record,
  xmlattributes(cm.manifestation_id as opac_id, a.idvolume as bm_id),
  xmlconcat(
   xmlelement(name titolo,
       CASE WHEN cm.title is null THEN
           a.titolo || ' - ' || a.autore || ' - ' || a.interpreti
       ELSE trim(cm.title)
       END
   ),
   xmlelement(name collocazione,
    CASE WHEN ci.collocation is null THEN replace(collocazione,' ','') ELSE ci.collocation END))
  )
 from bm_audiovisivi.t_volumi a left
join av_manifestations av using(idvolume) left join clavis.item ci
using(manifestation_id) left join clavis.manifestation cm
using(manifestation_id)
where a.collocazione is not null
--   and a.idvolume=41
;


select '</root>';
SELECT xmlcomment('fine importazione: ' || now());
