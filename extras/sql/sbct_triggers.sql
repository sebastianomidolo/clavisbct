-- triggers relativi a tabelle sbct_acquisti - agosto 2022

set search_path to sbct_acquisti ;

DROP TRIGGER verify_sbct_acquisti_items ON sbct_acquisti.copie;
DROP TRIGGER sbct_acquisti_list_update ON sbct_acquisti.copie;
DROP TRIGGER sbct_acquisti_list_delete ON sbct_acquisti.copie;
DROP TRIGGER sbct_acquisti_list_insert ON sbct_acquisti.copie;
DROP TRIGGER sbct_acquisti_list_update ON sbct_acquisti.titoli;

CREATE OR REPLACE FUNCTION fnc_verify_sbct_acquisti_items() RETURNS trigger AS $$
DECLARE
BEGIN
-- RAISE NOTICE 'Agisco su id_copia %', NEW.id_copia;
--RAISE NOTICE 'PRIMA: OLD order_status: % / data_arrivo: % / order_id: %', OLD.order_status, OLD.data_arrivo, OLD.order_id;
--RAISE NOTICE 'PRIMA: NEW order_status: % / data_arrivo: % / order_id: %', NEW.order_status, NEW.data_arrivo, NEW.order_id;

--IF NEW.order_status NOT IN ('O','A') OR NEW.order_status IS NULL  THEN
--       NEW.order_date = NULL;
--END IF;
IF NEW.order_status = 'A' AND OLD.order_status IN ('O','N') THEN
--  RAISE NOTICE 'order_status cambiato da % a %', OLD.order_status, NEW.order_status;
  IF NEW.data_arrivo is null THEN
   NEW.data_arrivo = now();
  END IF;
END IF;

IF NEW.order_status != 'A' THEN
--  RAISE NOTICE 'order_status cambiato da % a %', OLD.order_status, NEW.order_status;
  NEW.data_arrivo = NULL;
END IF;


--RAISE NOTICE ' DOPO: OLD order_status: % / data_arrivo: % / order_id: %', OLD.order_status, OLD.data_arrivo, OLD.order_id;
--RAISE NOTICE ' DOPO: NEW order_status: % / data_arrivo: % / order_id: %', NEW.order_status, NEW.data_arrivo, NEW.order_id;


RETURN NEW;
END;
$$
LANGUAGE plpgsql;

CREATE TRIGGER verify_sbct_acquisti_items BEFORE UPDATE ON sbct_acquisti.copie FOR EACH ROW EXECUTE PROCEDURE fnc_verify_sbct_acquisti_items();

/*********************************************************
 *  Inserimento automatico di titoli in liste d'acquisto *
 *  in base alla selezione fatta a livello di copia      *
 *********************************************************/

CREATE OR REPLACE FUNCTION delete_from_l_titoli_liste(id_copia integer) RETURNS boolean AS $$
BEGIN
  -- RAISE NOTICE 'In delete_from_l_titoli_liste con id_copia = %', id_copia;
  EXECUTE 'DELETE
  FROM  sbct_acquisti.l_titoli_liste tl
  USING sbct_acquisti.copie c,
        sbct_acquisti.liste l
 WHERE c.id_copia=$1 AND tl.id_titolo = c.id_titolo
       AND tl.id_lista = l.id_lista
       and l.owner_id=c.created_by and l.default_list=true'
 USING id_copia;

RETURN true;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION insert_into_l_titoli_liste(id_titolo integer) RETURNS boolean AS $$
BEGIN
  -- RAISE NOTICE 'In insert_into_l_titoli_liste con id_titolo = %', id_titolo;
  EXECUTE 'INSERT into sbct_acquisti.l_titoli_liste(id_titolo,id_lista) 
   ( 
  select distinct c.id_titolo,l.id_lista 
    from sbct_acquisti.titoli t join sbct_acquisti.copie c using(id_titolo) 
      join sbct_acquisti.liste l on (l.owner_id=c.created_by and l.default_list=true) 
       where c.id_titolo=$1 AND c.order_status=''S''
   ) on conflict(id_titolo,id_lista) DO NOTHING'
 USING id_titolo;
RETURN true;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION insert_into_l_titoli_liste() RETURNS boolean AS $$
BEGIN
  -- RAISE NOTICE 'In insert_into_l_titoli_liste - riallineamento generale indipendente da id_titolo';
  EXECUTE 'INSERT into sbct_acquisti.l_titoli_liste(id_titolo,id_lista)
   (select distinct c.id_titolo,l.id_lista
     from sbct_acquisti.titoli t join sbct_acquisti.copie c using(id_titolo)
      join sbct_acquisti.liste l on (l.owner_id=c.created_by and l.default_list=true)
            where c.order_status=''S'') on conflict(id_titolo,id_lista) DO NOTHING';
RETURN true;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION fnc_sbct_acquisti_list_update() RETURNS trigger AS $$
DECLARE
BEGIN
 -- RAISE NOTICE 'TG_OP: %', TG_OP;

IF TG_OP='DELETE' THEN
 -- RAISE NOTICE 'Delete per copia con id_copia %', OLD.id_copia;
 EXECUTE 'SELECT sbct_acquisti.delete_from_l_titoli_liste($1)' USING OLD.id_copia;
 -- EXECUTE 'SELECT insert_into_l_titoli_liste($1)' USING OLD.id_titolo;
 RETURN OLD;
END IF;

IF TG_OP='INSERT' THEN
 -- RAISE NOTICE 'Insert';
 EXECUTE 'SELECT sbct_acquisti.insert_into_l_titoli_liste($1)' USING NEW.id_titolo;
 RETURN NEW;
END IF;

-- RAISE NOTICE 'Inserisco/rimuovo da sbct_list partendo dalla copia con id_copia % con titolo con id_titolo %', NEW.id_copia, NEW.id_titolo;


IF OLD.order_status = 'S' AND NEW.order_status is null OR NEW.order_status != OLD.order_status THEN
  -- RAISE NOTICE 'order_status cambiato da % a % - rimuovo da lista', OLD.order_status, NEW.order_status;
  EXECUTE 'SELECT sbct_acquisti.delete_from_l_titoli_liste($1)' USING NEW.id_copia;
ELSE
  -- RAISE NOTICE 'inserisco in lista';
  EXECUTE 'SELECT sbct_acquisti.insert_into_l_titoli_liste($1)' USING NEW.id_titolo;
END IF;

RETURN NEW;
END;
$$
LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION fnc_sbct_acquisti_titles_update() RETURNS trigger AS $$
DECLARE
BEGIN
  EXECUTE 'SELECT sbct_acquisti.insert_into_l_titoli_liste()';
RETURN NEW;
END;
$$
LANGUAGE plpgsql;

CREATE TRIGGER sbct_acquisti_list_update AFTER UPDATE ON sbct_acquisti.copie FOR EACH ROW EXECUTE PROCEDURE fnc_sbct_acquisti_list_update();
CREATE TRIGGER sbct_acquisti_list_delete BEFORE DELETE ON sbct_acquisti.copie FOR EACH ROW EXECUTE PROCEDURE fnc_sbct_acquisti_list_update();
CREATE TRIGGER sbct_acquisti_list_insert AFTER INSERT ON sbct_acquisti.copie FOR EACH ROW EXECUTE PROCEDURE fnc_sbct_acquisti_list_update();

CREATE TRIGGER sbct_acquisti_list_update AFTER UPDATE ON sbct_acquisti.titoli FOR EACH ROW EXECUTE PROCEDURE fnc_sbct_acquisti_titles_update();

--begin;
--update sbct_acquisti.copie set order_status = NULL  where id_copia=577068;
--update sbct_acquisti.copie set order_status = 'S'  where id_copia=577068;
--delete from sbct_acquisti.copie where id_copia=577068;

--insert into sbct_acquisti.copie (id_titolo,id_copia,order_status,library_id, created_by) values(417489,577068,'S',3,9);
--rollback;
