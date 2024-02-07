-- Imposta anno di acquisizione sugli esemplari che non hanno acquisition_year impostato



update clavis.collocazioni c set acquisition_year = i.acquisition_year from clavis.item i where c.acquisition_year is null
   and i.item_id=c.item_id and i.acquisition_year is not null;

update clavis.collocazioni c set acquisition_year = date_part('year', i.inventory_date) from clavis.item i where c.acquisition_year is null
   and i.item_id=c.item_id and i.inventory_date is not null;
