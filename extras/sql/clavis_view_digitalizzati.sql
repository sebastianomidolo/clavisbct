
-- DROP VIEW clavis.digitalizzati;

CREATE OR REPLACE VIEW clavis.digitalizzati AS

select bib_level,bib_type,created_by,modified_by,bid_source, bid, manifestation_id, title
  from clavis.manifestation cm join
  (select attachable_id as manifestation_id from attachments
  where attachable_type='ClavisManifestation'
--    and attachment_category_id!='A'
   group by attachable_id) as x
  using(manifestation_id);
