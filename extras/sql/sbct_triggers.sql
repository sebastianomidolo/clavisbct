-- triggers relativi a tabelle sbct_acquisti - agosto 2022

DROP TRIGGER verify_sbct_acquisti_items ON sbct_acquisti.copie;

CREATE OR REPLACE FUNCTION fnc_verify_sbct_acquisti_items() RETURNS trigger AS $$
DECLARE
BEGIN
-- RAISE NOTICE 'Agisco su id_copia %', NEW.id_copia;
-- RAISE NOTICE 'OLD order_status: % / order_date: %', OLD.order_status, OLD.order_date;
-- RAISE NOTICE 'NEW order_status: % / order_date: %', NEW.order_status, NEW.order_date;

IF NEW.order_status NOT IN ('O','A') OR NEW.order_status IS NULL  THEN
       NEW.order_date = NULL;
END IF;

RETURN NEW;
END;
$$
LANGUAGE plpgsql;

CREATE TRIGGER verify_sbct_acquisti_items BEFORE UPDATE
  ON sbct_acquisti.copie FOR EACH ROW EXECUTE PROCEDURE fnc_verify_sbct_acquisti_items();


