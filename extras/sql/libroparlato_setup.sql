ALTER TABLE libroparlato.catalogo ADD PRIMARY KEY(id);
CREATE INDEX catalogo_n_idx ON libroparlato.catalogo(n);

ALTER TABLE libroparlato.catalogo ADD COLUMN manifestation_id INTEGER;
CREATE INDEX libroparlato_catalogo_manifestation_id_idx ON libroparlato.catalogo(manifestation_id);

UPDATE libroparlato.catalogo AS lp SET manifestation_id=ci.manifestation_id
  FROM clavis.item ci WHERE lp.manifestation_id is null AND
      ci.owner_library_id=29 AND inventory_serie_id!='TZ' AND
      ci.manifestation_id!=0 AND
      lp.n=replace(ci.collocation,'CD ','');

ALTER TABLE libroparlato.catalogo ALTER COLUMN cassette TYPE INTEGER;
UPDATE libroparlato.catalogo SET cassette=NULL WHERE cassette=0;

ALTER TABLE libroparlato.catalogo ADD COLUMN first_mp3_filename char(254);
UPDATE libroparlato.catalogo AS lp SET first_mp3_filename=o.filename
  FROM attachments a, d_objects o WHERE lp.first_mp3_filename IS NULL
     AND a.attachable_type='ClavisManifestation'
     AND a.attachment_category_id='D' AND o.id=a.d_object_id AND a.position=1
     AND lp.manifestation_id=a.attachable_id;
