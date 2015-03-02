DROP TRIGGER update_open_shelf_items ON public.open_shelf_items;

CREATE OR REPLACE FUNCTION update_open_shelf_items() RETURNS trigger AS $$
switch $TG_op {
    "INSERT" {
        # elog NOTICE "Creazione: [array get NEW]";
	set cmd "UPDATE clavis.item SET openshelf=true WHERE item_id='$NEW(item_id)'"
	spi_exec $cmd
        return [array get NEW];
    }
    "DELETE" {
        # elog NOTICE "Cancellazione: [array get OLD]";
	set cmd "UPDATE clavis.item SET openshelf=false WHERE item_id='$OLD(item_id)'"
	spi_exec $cmd
        return [array get OLD];
    }
}
$$ LANGUAGE pltcl;
CREATE TRIGGER update_open_shelf_items AFTER INSERT OR DELETE
  ON public.open_shelf_items FOR EACH ROW EXECUTE PROCEDURE update_open_shelf_items();

