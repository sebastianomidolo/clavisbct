
BEGIN;

DELETE FROM public.attachments WHERE attachable_type='IssPage';
INSERT INTO public.attachments(d_object_id,attachable_id,attachable_type)
   (select o.id,p.id,'IssPage' from public.d_objects o join iss.pages p
    ON(o.filename='seshat/archives/' || p.imagepath));

DELETE FROM public.attachments WHERE attachable_type='ProculturaCard';
INSERT INTO public.attachments(d_object_id,attachable_id,attachable_type)
   (select o.id,p.id,'ProculturaCard' from public.d_objects o join procultura.cards p
    ON(o.filename='procultura/archives/' || p.filepath));

/* Esempio di insert basato su filename : conosco in anticipo attachable_id */

DELETE FROM public.attachments WHERE attachable_type='ClavisManifestation';
DELETE FROM public.attachments WHERE attachable_type='ClavisItem';

INSERT INTO public.attachments(d_object_id,attachable_id,attachable_type)
   (select id,53650,'ClavisManifestation' from public.d_objects
    WHERE filename ~* 'hd1/Luraghi/tif');

/* Capire se sia meglio legarlo all'esemplare
INSERT INTO public.attachments(d_object_id,attachable_id,attachable_type)
   (select id,71929,'ClavisItem' from public.d_objects
    WHERE filename ~* 'hd1/Luraghi/tif');

INSERT INTO public.attachments(d_object_id,attachable_id,attachable_type)
   (select id,500700,'ClavisItem' from public.d_objects
    WHERE filename ~* 'hd2/La lotta della Giovent');
*/

INSERT INTO public.attachments(d_object_id,attachable_id,attachable_type)
   (select id,81210,'ClavisManifestation' from public.d_objects
    WHERE filename ~* 'hd2/La lotta della Giovent');

INSERT INTO public.attachments(d_object_id,attachable_id,attachable_type)
   (select id,338747,'ClavisManifestation' from public.d_objects
    WHERE filename ~* 'hd2/Persepolis');

INSERT INTO public.attachments(d_object_id,attachable_id,attachable_type)
   (select id,53650,'ClavisManifestation' from public.d_objects
    WHERE filename ~* 'hd1/Luraghi/tif');



COMMIT;

/* Inserimento clips_mp3 della biblioteca musicale (owner_library_id=3) */
/* Nota: per funzionare, bisogna che prima siano stati inseriti i metadati da bctaudio:
   (cd /home/ror/bctaudio; rake export_fileinfo_metadata > /tmp/bctaudio_metadata.sql)
 */
/*
Non conviene eseguirla in fase di test, è molto lunga:
\i /tmp/bctaudio_metadata.sql

Andrebbe anche eseguito questo:
rake allinea_collocazioni
Nota (27 maggio 2013): resta ancora da definire l'ordine dei vari passaggi.
*/

BEGIN;
create temp table temp_d_objects_collocation as
 select id,(xpath('/r/@collocation',tags))[1]::text as collocation
  from d_objects where tags notnull;
create INDEX temp_d_objects_collocation_idx on temp_d_objects_collocation(collocation);
update temp_d_objects_collocation set collocation=substr(collocation,5) where collocation ~* '^BCT' ;

INSERT INTO public.attachments(d_object_id,attachable_id,attachable_type,attachment_category_id)
 (SELECT DISTINCT o.id,i.manifestation_id,'ClavisManifestation','A' FROM temp_d_objects_collocation o
   JOIN clavis.item i USING(collocation) WHERE i.owner_library_id=3 and i.manifestation_id!=0);

UPDATE public.attachments a SET position=unnest(xpath('//r/tracknum/text()',o.tags))::text::integer
  FROM public.d_objects o WHERE(a.d_object_id=o.id) AND a.position ISNULL;

COMMIT;
