-- DROP TRIGGER aggiorna_clavis_collocazioni ON clavis.item;
DROP TRIGGER aggiorna_topografico_non_in_clavis ON public.topografico_non_in_clavis;

CREATE OR REPLACE FUNCTION aggiorna_clavis_collocazioni() RETURNS trigger AS $$
switch $TG_op {
    "UPDATE" {
       	# elog NOTICE "aggiornamento da [array get OLD]";
	# elog NOTICE "diventa [array get NEW]";
	set cmd "UPDATE clavis.collocazioni AS cc SET collocazione=ci.collocation, \
	   sort_text=public.espandi_collocazione(ci.collocation) FROM clavis.item ci \
	     WHERE cc.item_id=$NEW(item_id) AND ci.item_id=cc.item_id"
	# elog NOTICE $cmd
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
             date_created,custom_field1,custom_field3) \
           (SELECT 0,-1,owner_library_id,inventory_serie_id,inventory_number, \
             collocazione,titolo,'F',0,'',created_at,note,id \
           FROM public.topografico_non_in_clavis WHERE id=$NEW(id))"
}

switch $TG_op {
    "UPDATE" {
       	# elog NOTICE "aggiornamento da [array get OLD]";
	# elog NOTICE "diventa [array get NEW]";
	# elog NOTICE "deleted: $NEW(deleted)";
	if { [info exists NEW(deleted)] && $NEW(deleted) } {
	   # elog NOTICE "Cancellato!";
           set cmd "DELETE FROM clavis.item WHERE home_library_id=-1 AND custom_field3='$NEW(id)'"
        } else {
	   # elog NOTICE "clavis.item DA AGGIORNARE";
	   set cmd "SELECT item_id FROM clavis.item  WHERE home_library_id=-1 AND custom_field3='$NEW(id)'"
 	   set found [spi_exec $cmd]
	   if { $found==0 } {
	     set cmd [inserisci_record NEW]
	   } else {
             set cmd "UPDATE clavis.item AS ci SET collocation=t.collocazione, \
	        inventory_serie_id=t.inventory_serie_id, \
	        inventory_number=t.inventory_number, title=t.titolo \
                  FROM public.topografico_non_in_clavis t \
               WHERE ci.home_library_id=-1 AND ci.custom_field3='$NEW(id)' AND ci.custom_field3::text=t.id::text"
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
	set cmd "DELETE FROM clavis.item WHERE home_library_id=-1 AND custom_field3='$OLD(id)'"
	spi_exec $cmd
        return [array get OLD];
    }
}
$$ LANGUAGE pltcl;
CREATE TRIGGER aggiorna_topografico_non_in_clavis AFTER UPDATE OR INSERT OR DELETE
  ON public.topografico_non_in_clavis FOR EACH ROW EXECUTE PROCEDURE aggiorna_topografico_non_in_clavis();
