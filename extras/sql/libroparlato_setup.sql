ALTER TABLE libroparlato.catalogo ADD PRIMARY KEY(id);
CREATE INDEX catalogo_n_idx ON libroparlato.catalogo(n);

ALTER TABLE libroparlato.catalogo ADD COLUMN manifestation_id INTEGER;
CREATE INDEX libroparlato_catalogo_manifestation_id_idx ON libroparlato.catalogo(manifestation_id);

DELETE  FROM  libroparlato.catalogo WHERE non_disponibile = '1';

UPDATE libroparlato.catalogo AS lp SET manifestation_id=ci.manifestation_id
  FROM clavis.item ci WHERE lp.manifestation_id is null AND
      ci.home_library_id=2 AND ci.manifestation_id!=0 AND
      ci.item_status!='E' AND ci.section='LP' AND
      replace(lp.n,' ','')=replace(replace(ci.collocation,'CD ',''),' ','');

ALTER TABLE libroparlato.catalogo ALTER COLUMN cassette TYPE INTEGER;
UPDATE libroparlato.catalogo SET cassette=NULL WHERE cassette=0;

ALTER TABLE libroparlato.catalogo ADD COLUMN first_mp3_filename char(254);

ALTER TABLE libroparlato.catalogo ADD COLUMN d_objects_folder_id integer;
-- DELETE  FROM  libroparlato.catalogo WHERE manifestation_id IS NULL;

delete from libroparlato.catalogo where n isnull;
