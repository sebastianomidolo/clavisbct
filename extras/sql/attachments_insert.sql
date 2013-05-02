
BEGIN;

DELETE FROM public.attachments WHERE attachable_type='IssPage';
INSERT INTO public.attachments(d_object_id,attachable_id,attachable_type)
   (select o.id,p.id,'IssPage' from public.d_objects o join iss.pages p
    ON(o.filename='seshat/archives/' || p.imagepath));

DELETE FROM public.attachments WHERE attachable_type='ProculturaCard';
INSERT INTO public.attachments(d_object_id,attachable_id,attachable_type)
   (select o.id,p.id,'ProculturaCard' from public.d_objects o join procultura.cards p
    ON(o.filename='procultura/archives/' || p.filepath));

COMMIT;
