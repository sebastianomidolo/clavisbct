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

