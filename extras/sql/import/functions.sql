
SET SEARCH_PATH TO import;

CREATE OR REPLACE FUNCTION format_collocation( i item)
RETURNS text AS $$
  BEGIN
  RETURN rtrim(CONCAT_WS('.',
    case when i.section!=E'BCT' then i.section end,
    case when i.collocation ~ E'^BCT\\.' then substr(i.collocation, 5) else i.collocation end,
      i.specification, i.sequence1, i.sequence2), '.');
  END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION public.unimarc_105(unimarc_xml xml, pos integer) RETURNS char AS $$
DECLARE
 coded_dat char;
 BEGIN
  SELECT substr((xpath('//d105/sa/text()',unimarc_xml::xml))[1]::char(14),pos+1,1) into coded_dat;
 RETURN coded_dat;
 END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION public.unimarc_100(unimarc_xml xml, pos integer, len integer) RETURNS varchar AS $$
DECLARE
 coded_dat varchar;
 BEGIN
  SELECT substr((xpath('//d100/sa/text()',unimarc_xml::xml))[1]::varchar,pos+1,len) into coded_dat;
 RETURN coded_dat;
 END;
$$ LANGUAGE plpgsql;


-- set search_path to public;
CREATE OR REPLACE FUNCTION location_sql( l public.locations )
RETURNS text AS $$
  BEGIN
    -- RETURN CONCAT_WS(';', l.id,l.sql_filter);
    RETURN l;
  END;
$$ LANGUAGE plpgsql;

--SELECT loc, location_sql(loc) FROM public.locations loc JOIN public.bib_sections bs
--  ON bs.id = loc.bib_section_id where bs.library_id = 2
--   order by locked desc,primo nulls last,secondo nulls last limit 10;

-- select location_sql(l) from public.locations l ;
-- SET SEARCH_PATH TO import;
