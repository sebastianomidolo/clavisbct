-- Da commentare in produzione:
-- DROP TRIGGER aggiorna_clavis_collocazioni ON clavis.item;
-- DROP TRIGGER aggiorna_centrale_locations ON clavis.collocazioni;
-- DROP TRIGGER aggiorna_clavis_ricollocati ON clavis.item;

-- Da non commentare:
DROP TRIGGER aggiorna_topografico_non_in_clavis ON public.topografico_non_in_clavis;

CREATE OR REPLACE FUNCTION aggiorna_clavis_collocazioni() RETURNS trigger AS $$
switch $TG_op {
    "UPDATE" {
       	# elog NOTICE "aggiornamento da [array get OLD]";
	# elog NOTICE "diventa [array get NEW]";
	set cmd "UPDATE clavis.collocazioni AS cc  SET collocazione = \
	 public.compact_collocation(ci.\"section\",ci.collocation,ci.specification,ci.sequence1,ci.sequence2)
           FROM clavis.item ci WHERE cc.item_id=$NEW(item_id) AND ci.item_id=cc.item_id; \
         UPDATE clavis.collocazioni SET sort_text=public.espandi_collocazione(collocazione) WHERE item_id=$NEW(item_id)"
	spi_exec $cmd
	return [array get NEW];
    }
    "INSERT" {
    	# elog NOTICE "Creazione: [array get NEW]";
	set cmd "INSERT INTO clavis.collocazioni(item_id,collocazione) \
          (SELECT item_id,public.compact_collocation(\"section\",collocation,specification,sequence1,sequence2) \
           FROM clavis.item WHERE item_id=$NEW(item_id)); \
	   UPDATE clavis.collocazioni SET sort_text=public.espandi_collocazione(collocazione) \
	   WHERE item_id=$NEW(item_id)"
	spi_exec $cmd
        return [array get NEW];
    }
    "DELETE" {
        # elog NOTICE "Cancellazione: [array get OLD]";
	set cmd "DELETE FROM clavis.collocazioni WHERE item_id=$OLD(item_id)"
	# elog NOTICE $cmd
	spi_exec $cmd
        return [array get OLD];
    }
}
$$ LANGUAGE pltcl;

CREATE TRIGGER aggiorna_clavis_collocazioni AFTER UPDATE OR INSERT OR DELETE
  ON clavis.item FOR EACH ROW EXECUTE PROCEDURE aggiorna_clavis_collocazioni();


CREATE OR REPLACE FUNCTION aggiorna_topografico_non_in_clavis() RETURNS trigger AS $$
proc inserisci_record {newrec} {
  upvar $newrec NEW
  return "INSERT INTO clavis.item(manifestation_id,home_library_id,owner_library_id,inventory_serie_id, \
             inventory_number,collocation,title,item_media,issue_number,item_icon, \
             date_created,custom_field3) \
           (SELECT 0,home_library_id,-1,inventory_serie_id,inventory_number, \
             collocazione, CASE WHEN note_interne NOTNULL THEN titolo || ' \[note: ' || note_interne || '\]' ELSE titolo END as titolo, 'F',0,'',created_at,id \
           FROM public.topografico_non_in_clavis WHERE id=$NEW(id))"
}

switch $TG_op {
    "UPDATE" {
       	# elog NOTICE "aggiornamento da [array get OLD]";
	# elog NOTICE "diventa [array get NEW]";
	# elog NOTICE "deleted: $NEW(deleted)";
	if { [info exists NEW(deleted)] && $NEW(deleted) } {
	   # elog NOTICE "Cancellato!";
           set cmd "DELETE FROM clavis.item WHERE owner_library_id=-1 AND custom_field3='$NEW(id)'"
        } else {
	   # elog NOTICE "clavis.item DA AGGIORNARE";
	   set cmd "SELECT item_id FROM clavis.item  WHERE owner_library_id=-1 AND custom_field3='$NEW(id)'"
 	   set found [spi_exec $cmd]
	   if { $found==0 } {
	     set cmd [inserisci_record NEW]
	   } else {
             set cmd "UPDATE clavis.item AS ci SET collocation=t.collocazione, \
	        inventory_serie_id=t.inventory_serie_id, \
	        inventory_number=t.inventory_number, title=CASE WHEN t.note_interne != '' THEN t.titolo || ' \[note: ' || t.note_interne || '\]' ELSE t.titolo END \
                  FROM public.topografico_non_in_clavis t \
               WHERE ci.owner_library_id=-1 AND ci.custom_field3='$NEW(id)' AND ci.custom_field3::text=t.id::text"
           }
        }
	# elog NOTICE $cmd
	spi_exec $cmd
	return [array get NEW];
    }
    "INSERT" {
    	# elog NOTICE "Creazione: [array get NEW]";
        spi_exec [inserisci_record NEW]
        return [array get NEW];
    }
    "DELETE" {
        # elog NOTICE "Cancellazione: [array get OLD]";
	set cmd "DELETE FROM clavis.item WHERE owner_library_id=-1 AND custom_field3='$OLD(id)'"
	spi_exec $cmd
        return [array get OLD];
    }
}
$$ LANGUAGE pltcl;
CREATE TRIGGER aggiorna_topografico_non_in_clavis AFTER UPDATE OR INSERT OR DELETE
  ON public.topografico_non_in_clavis FOR EACH ROW EXECUTE PROCEDURE aggiorna_topografico_non_in_clavis();


CREATE OR REPLACE FUNCTION aggiorna_centrale_locations() RETURNS trigger AS $$
switch $TG_op {
    "UPDATE" {
        # elog NOTICE "aggiorna_centrale_locations() - aggiornamento da [array get OLD]";
        set cmd "SELECT item_id FROM clavis.centrale_locations l JOIN clavis.item i using(item_id) WHERE l.item_id='$NEW(item_id)' AND home_library_id=2"
        set found [spi_exec $cmd]
        if { $found==0 } {
 	  # elog NOTICE "aggiorna_centrale_locations() dice: non esiste entry per ora"
          set cmd "SELECT true FROM clavis.item WHERE item_id=$NEW(item_id) AND home_library_id=2"
          set found_in_clavis_items [spi_exec $cmd]
          if { $found_in_clavis_items==1 } {
            set cmd "INSERT INTO clavis.centrale_locations (item_id,collocazione) VALUES($NEW(item_id),'$NEW(collocazione)')"
            spi_exec $cmd
	  }
        } else {
          # elog NOTICE "aggiorna_centrale_locations() dice: trovata entry"
	  if { $NEW(collocazione)!=$OLD(collocazione) } {
            set cmd "UPDATE clavis.centrale_locations SET collocazione='$NEW(collocazione)' WHERE item_id='$NEW(item_id)'"
            # elog NOTICE "\ncmd=$cmd"
	    spi_exec $cmd
	  } else {
           # elog NOTICE "Collocazione non cambiata, non effetuo la UPDATE"
	  }
	}
	return [array get NEW];
    }
    "INSERT" {
        set cmd "SELECT true FROM clavis.item WHERE item_id=$NEW(item_id) AND home_library_id=2"
	elog NOTICE "\ncmd=$cmd"
        set found_in_clavis_items [spi_exec $cmd]
        if { $found_in_clavis_items==1 } {
          set cmd "INSERT INTO clavis.centrale_locations (item_id,collocazione) VALUES($NEW(item_id),'$NEW(collocazione)')"
	  elog NOTICE "\ncmd=$cmd"
	  spi_exec $cmd
        }
        return [array get NEW];
    }
    "DELETE" {
        # elog NOTICE "Cancellazione: [array get OLD]";
	set cmd "DELETE FROM clavis.centrale_locations WHERE item_id=$OLD(item_id)"
	spi_exec $cmd
        return [array get OLD];
    }
}
$$ LANGUAGE pltcl;
CREATE TRIGGER aggiorna_centrale_locations AFTER UPDATE OR INSERT OR DELETE
   ON clavis.collocazioni FOR EACH ROW EXECUTE PROCEDURE aggiorna_centrale_locations();


CREATE OR REPLACE FUNCTION aggiorna_clavis_ricollocati() RETURNS trigger AS $$
switch $TG_op {
    "UPDATE" {
       	# elog NOTICE "aggiornamento da [array get OLD]";
	# elog NOTICE "diventa [array get NEW]";
	set cmd "UPDATE clavis.item ir SET title=ci.title,item_status=ci.item_status,loan_status=ci.loan_status, \
	        opac_visible=ci.opac_visible,date_updated=ci.date_updated \
             from clavis.item ci where ci.item_id=$NEW(item_id) and ir.owner_library_id = -3 \
            and ir.custom_field1=ci.item_id::varchar;"
        # elog NOTICE "\ncmd=$cmd"
	spi_exec $cmd
	return [array get NEW];
    }
}
$$ LANGUAGE pltcl;

CREATE TRIGGER aggiorna_clavis_ricollocati AFTER UPDATE
  ON clavis.item FOR EACH ROW EXECUTE PROCEDURE aggiorna_clavis_ricollocati();


CREATE OR REPLACE FUNCTION aggiorna_clavisitem_talking_book_id() RETURNS trigger AS $$
switch $TG_op {
    "UPDATE" {
	set NEW(talking_book_id) $NEW(custom_field1);
	elog NOTICE "custom field 1: $NEW(custom_field1) ; talking_book_id old: $OLD(talking_book_id) => $NEW(talking_book_id)";
        elog NOTICE "aggiornamento da [array get OLD]";
	elog NOTICE "diventa [array get NEW]";
	return [array get NEW];
    }
}
$$ LANGUAGE pltcl;

CREATE TRIGGER aggiorna_clavisitem_talking_book_id BEFORE UPDATE
  ON clavis.item FOR EACH ROW
   WHEN (NEW.custom_field1 ~ '^[0-9\.]+$' AND NEW.item_media='T' AND NEW.section='LP')
  EXECUTE PROCEDURE aggiorna_clavisitem_talking_book_id();

