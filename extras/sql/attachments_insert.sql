
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
/*
INSERT INTO public.attachments(d_object_id,attachable_id,attachable_type)
   (select id,53650,'ClavisManifestation' from public.d_objects
    WHERE filename ~* 'hd1/Luraghi/tif');
*/

/* Meglio legarlo all'esemplare */
INSERT INTO public.attachments(d_object_id,attachable_id,attachable_type)
   (select id,71929,'ClavisItem' from public.d_objects
    WHERE filename ~* 'hd1/Luraghi/tif');

INSERT INTO public.attachments(d_object_id,attachable_id,attachable_type)
   (select id,500700,'ClavisItem' from public.d_objects
    WHERE filename ~* 'hd2/La lotta della Giovent');

/* Questo invece lo lego alla manifestation */
INSERT INTO public.attachments(d_object_id,attachable_id,attachable_type)
   (select id,338747,'ClavisManifestation' from public.d_objects
    WHERE filename ~* 'hd2/Persepolis');



COMMIT;

