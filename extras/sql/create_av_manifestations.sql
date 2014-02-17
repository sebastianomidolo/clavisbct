
UPDATE bm_audiovisivi.t_volumi AS tv
 SET manifestation_id=ci.manifestation_id
  FROM clavis.item ci WHERE tv.manifestation_id IS NULL AND
   replace(collocazione,' ','')=ci.collocation
   AND ci.manifestation_id!=0 AND collocazione!='' AND ci.owner_library_id=3;

UPDATE bm_audiovisivi.t_volumi set interpreti = regexp_replace(interpreti, '(;| )+$', '');
UPDATE bm_audiovisivi.t_volumi set interpreti = null where interpreti='';

/*

BEGIN;
DROP TABLE public.av_manifestations;
COMMIT;

CREATE TABLE public.av_manifestations as select distinct bm.idvolume,ci.manifestation_id
   from bm_audiovisivi.t_volumi bm join clavis.item ci on(replace(collocazione,' ','')=collocation
      and ci.manifestation_id!=0) where bm.collocazione!=''
      and ci.owner_library_id=3
  UNION SELECT idvolume,manifestation_id from bm_audiovisivi.t_volumi where manifestation_id notnull
;

CREATE UNIQUE INDEX av_manifestation_idx on av_manifestations(idvolume,manifestation_id);

CREATE INDEX av_manifestation_manifestation_id_idx on av_manifestations(manifestation_id);
CREATE INDEX av_manifestation_idvolume_idx on av_manifestations(idvolume);

-- In attesa di una soluzione, inserisco a mano:
INSERT INTO av_manifestations (idvolume , manifestation_id) VALUES (135,539578);
INSERT INTO av_manifestations (idvolume , manifestation_id) VALUES (41,350456);

*/

