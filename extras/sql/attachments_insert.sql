/* NON USARE */

BEGIN;

/* Non è necessario ripetere delete/insert in questi due casi:

DELETE FROM public.attachments WHERE attachable_type='IssPage';
INSERT INTO public.attachments(d_object_id,attachable_id,attachable_type)
   (select o.id,p.id,'IssPage' from public.d_objects o join iss.pages p
    ON(o.filename='seshat/archives/' || p.imagepath));

DELETE FROM public.attachments WHERE attachable_type='ProculturaCard';
INSERT INTO public.attachments(d_object_id,attachable_id,attachable_type)
   (select o.id,p.id,'ProculturaCard' from public.d_objects o join procultura.cards p
    ON(o.filename='procultura/archives/' || p.filepath));
*/


/* Esempio di insert basato su filename : conosco in anticipo attachable_id */

/*
DELETE FROM public.attachments WHERE attachable_type='ClavisManifestation';
DELETE FROM public.attachments WHERE attachable_type='ClavisItem';

INSERT INTO public.attachments(d_object_id,attachable_id,attachable_type,attachment_category_id)
   (select id,53650,'ClavisManifestation','C' from public.d_objects
    WHERE filename ~* 'hd1/Luraghi/tif');

*/



/* Capire se sia meglio legarlo all'esemplare
INSERT INTO public.attachments(d_object_id,attachable_id,attachable_type)
   (select id,71929,'ClavisItem' from public.d_objects
    WHERE filename ~* 'hd1/Luraghi/tif');

INSERT INTO public.attachments(d_object_id,attachable_id,attachable_type)
   (select id,500700,'ClavisItem' from public.d_objects
    WHERE filename ~* 'hd2/La lotta della Giovent');
*/

/*
INSERT INTO public.attachments(d_object_id,attachable_id,attachable_type)
   (select id,81210,'ClavisManifestation' from public.d_objects
    WHERE filename ~* 'hd2/La lotta della Giovent');


INSERT INTO public.attachments(d_object_id,attachable_id,attachable_type)
   (select id,15432,'ClavisManifestation' from public.d_objects
    WHERE filename ~* '/fischietto/Fischietto_1848');


INSERT INTO public.attachments(d_object_id,attachable_id,attachable_type)
   (select id,338747,'ClavisManifestation' from public.d_objects
    WHERE filename ~* 'hd2/Persepolis');


INSERT INTO public.attachments(d_object_id,attachable_id,attachable_type)
   (select id,67146,'ClavisManifestation' from public.d_objects
    WHERE filename ~* 'hd1/botta');
*/
COMMIT;

/*
UPDATE public.d_objects o SET tags=i.tags FROM public.import_bctaudio_metatags i
  WHERE(i.filename=o.filename);
*/

/* La DISTINCT qui è necessaria perché in clavis.item possono esserci più esemplari con identica
   "collocation", distinguibili per "specification", "sequence1", "sequence2"
   Esempio 
select item_id, manifestation_id, collocation,specification, sequence1
   from clavis.item where collocation='11.F.420';
 item_id | manifestation_id | collocation | specification | sequence1
---------+------------------+-------------+---------------+-----------
 1943110 |           561618 | 11.F.420    | CD            | 1
 1943111 |           561618 | 11.F.420    | CD            | 2
(2 rows)
*/

/*
Sostituito da extras/allinea_bm_audio.sh (13 febbraio 2014)
INSERT INTO public.attachments
  (d_object_id,attachable_id,attachable_type,attachment_category_id,position,folder)
  (
  select DISTINCT o.id,ci.manifestation_id, 'ClavisManifestation','A',i.tracknum,i.folder
    from import_bctaudio_metatags i join clavis.item ci using(collocation)
     join d_objects o using(filename) where ci.owner_library_id=3
      and ci.manifestation_id!=0
  );
*/

/*
INSERT INTO public.attachments
  (d_object_id,attachable_id,attachable_type,attachment_category_id,position)
  (
  select lp.d_object_id,ci.manifestation_id,'ClavisManifestation','D',lp.position
   from import_libroparlato_colloc lp join clavis.item ci
  on(replace(lp.collocation,'CD ','')=replace(ci.collocation,'CD ',''))
   join d_objects o on(lp.d_object_id=o.id)
   where section='LP' and owner_library_id=29 and ci.manifestation_id NOT IN (0,449004,441874)
     and ci.item_status='F'
        and o.mime_type='audio/mpeg; charset=binary'
  );

UPDATE public.d_objects SET access_right_id=2 WHERE access_right_id ISNULL AND filename ~ '^libroparlato/';
UPDATE public.d_objects SET access_right_id=0 WHERE access_right_id ISNULL AND filename ~ '^uac/locandine';
*/

/*
   Piano works / Schumann
*/
/*
UPDATE attachments set attachable_id = 522565 where attachable_id=355191
   and attachable_type = 'ClavisManifestation';
*/


/*
BEGIN;
-- See lib/tasks/find_d_objects.rake (DROP CONSTRAINT "d_object_id_fkey")
ALTER TABLE public.attachments ADD CONSTRAINT "d_object_id_fkey" FOREIGN KEY(d_object_id)
   REFERENCES d_objects ON UPDATE CASCADE ON DELETE CASCADE;
COMMIT;
*/
