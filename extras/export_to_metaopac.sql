\pset tuples_only t
\pset border 0
\pset pager f


SELECT xmlcomment('inizio esportazione: ' || now());

select '<root>';
select xmlelement(
 name record,
  xmlattributes(bid,manifestation_id as id,bib_level as biblevel,
         'BCT' as cod_polo, now() as "data", date_updated),
  xmlconcat(
   xmlelement(name title, trim(title)),
   xmlelement(name publisher, trim(publisher)),
   xmlforest((xpath('//d010/sa/text()',unimarc::xml))[1] as isbn),
   xmlforest((xpath('//d011/sa/text()',unimarc::xml))[1] as issn),
   xmlforest((xpath('//d100/sa/text()',unimarc::xml))[1] as u100),
   xmlforest((xpath('//d101/sa/text()',unimarc::xml))[1] as u101),
   xmlforest((xpath('//d102/sa/text()',unimarc::xml))[1] as u102),
   xmlelement(name copie, c.copie),
   xmlelement(name links, a.links)
  )
 )
  from clavis.manifestation cm
   left join clavis.export_copie c using(manifestation_id)
   left join clavis.export_authorities a using(manifestation_id)
   where cm.bib_level in ('m','s','a')
         and cm.bid_source='SBN'
  -- limit 10
;
SELECT xmlcomment('intermedio: ' || now());


select xmlelement(
 name record,
  xmlattributes(bid,manifestation_id as id,bib_level as biblevel,
         'BCT' as cod_polo, now() as "data", date_updated),
  xmlconcat(
   xmlelement(name title, trim(title)),
   xmlelement(name publisher, trim(publisher)),
   xmlforest((xpath('//d010/sa/text()',unimarc::xml))[1] as isbn),
   xmlforest((xpath('//d011/sa/text()',unimarc::xml))[1] as issn),
   xmlelement(name links, a.links),
   xmlelement(name linked_titles, l.linked_titles)
  )
 )
  from clavis.manifestation cm
   left join clavis.export_authorities a using(manifestation_id)
   left join clavis.export_collane l using(manifestation_id)
  where cm.bib_level='c'
--  limit 10
;



select '</root>';
SELECT xmlcomment('fine importazione: ' || now());
