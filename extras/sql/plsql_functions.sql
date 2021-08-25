CREATE OR REPLACE FUNCTION unimarc_coded_data(unimarc_xml xml, field_number integer,
                            subfield_tag char, pos integer) RETURNS char AS $$
DECLARE
 coded_dat char;
 BEGIN
  SELECT substr((xpath('//d110/s' || subfield_tag || '/text()',unimarc_xml::xml))[1]::char(24),pos+1,1) into coded_dat;
 RETURN coded_dat;
 END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION serial_frequency_of_issue(unimarc xml) RETURNS char AS $$
 BEGIN
  RETURN unimarc_coded_data(unimarc,110,'a',1);
 END;
$$ LANGUAGE plpgsql;


-- select unimarc_coded_data(unimarc::xml,110,'a'::character(1)) from clavis.manifestation where manifestation_id = 18086;
select unimarc_coded_data(unimarc::xml,110,'a',1) from clavis.manifestation where manifestation_id = 18086;
select uc.label, unimarc_coded_data(cm.unimarc::xml,110,'a',1)
    from clavis.manifestation cm join clavis.unimarc_codes uc
       on(uc.code_value::char=unimarc_coded_data(unimarc::xml,110,'a',1)::char)
     where
      uc.language='it_IT' and uc.field_number = 110 and uc.pos=1 and
      cm.manifestation_id = 18086;

select uc.label, serial_frequency_of_issue(cm.unimarc::xml) as frequency
    from clavis.manifestation cm join clavis.unimarc_codes uc
       on(uc.code_value::char=serial_frequency_of_issue(cm.unimarc::xml))
     where
      uc.language='it_IT' and uc.field_number = 110 and uc.pos=1 and
      cm.manifestation_id = 18086;
      
select uc.label, serial_frequency_of_issue(cm.unimarc::xml) as frequency
    from clavis.manifestation cm
      join clavis.unimarc_codes uc
        on(uc.code_value::char=serial_frequency_of_issue(cm.unimarc::xml)
             and uc.language='it_IT' and uc.field_number = 110 and uc.pos=1)
     where cm.manifestation_id = 18086;
     
 
CREATE OR REPLACE FUNCTION clavis_loans_dates_info(loan_date_begin timestamp[],loan_date_end timestamp[])
    RETURNS text AS $$
DECLARE
  retval text;
  tmpvar text;
BEGIN
FOR i IN 1 .. array_upper(loan_date_begin, 1)
  LOOP
    -- RAISE NOTICE '%: %, %', loan_ids[i], loan_date_begin[i], loan_date_end[i];
    tmpvar = CONCAT('Preso in prestito per ', DATE_PART('day', loan_date_end[i] - loan_date_begin[i]), ' giorni, dal <b>', to_char(loan_date_begin[i], 'DD-MM-YYYY'), '</b> al <b>', to_char(loan_date_end[i], 'DD-MM-YYYY'), '</b>');
    --    retval = CONCAT_WS('\n', retval, ('%: %, %', loan_ids[i], loan_date_begin[i], loan_date_end[i]));
    retval = CONCAT_WS('<br/>', retval, tmpvar);
  END LOOP;
RETURN retval;
END;

$$ LANGUAGE plpgsql;

