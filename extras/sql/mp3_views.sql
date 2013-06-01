BEGIN; DROP VIEW public.mp3_titles; COMMIT;
CREATE VIEW public.mp3_titles AS
 SELECT id,
  (xpath('//title/text()',tags))[1]::text AS mp3_title
 FROM d_objects
 WHERE (xpath('//title/text()',tags))[1]::text NOTNULL;

