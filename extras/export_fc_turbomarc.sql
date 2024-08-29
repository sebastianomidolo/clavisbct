\pset tuples_only t
\pset border 0
\pset pager f


SELECT xmlcomment('inizio esportazione: ' || now());
select '<r>';


/*
<d200 i1="1">
    <sa>*Vita di Oscar Wilde attraverso le lettere</sa>
    <sf>a cura di Masolino d'Amico</sf>
</d200>

   xmlforest(trim(title) as title, item_status, loan_class)

*/

select
  xmlconcat(
   xmlelement(name c001, 'fc ' || item_id),
   xmlelement(name c005, date_updated),
   xmlelement(name d200, xmlattributes('1' as "i1"),
   		   xmlelement(name sa, trim(title))),
   xmlelement(name d950, xmlattributes(' ' as "i1", '' as "i2"),
      		   xmlelement(name sa, home_library_id),
                   xmlelement(name sb, inventory_serie_id),
                   xmlelement(name sc, inventory_number),
		   xmlelement(name sd, "section"),
                   xmlelement(name sf, collocation),
                   xmlelement(name sg, specification),
                   xmlelement(name sl, c.collocazione))
  )
  from clavis.item ci join clavis.collocazioni c using(item_id)
   where
    ci.manifestation_id=0 and inventory_number > 0
    limit 1000
;




select '</r>';
SELECT xmlcomment('fine importazione: ' || now());


\pset tuples_only f
\pset border 1
\pset pager t

