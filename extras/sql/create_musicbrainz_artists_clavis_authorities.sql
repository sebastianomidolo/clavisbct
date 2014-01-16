CREATE TABLE public.musicbrainz_artists (gid uuid,sort_name character varying);
\COPY musicbrainz_artists (gid,sort_name) FROM /tmp/musicbrainz_artists.csv
CREATE INDEX musicbrainz_artists_gid_idx on musicbrainz_artists (gid);
CREATE INDEX musicbrainz_artists_sort_name_idx ON musicbrainz_artists (sort_name);
BEGIN;
DROP TABLE public.musicbrainz_artists_clavis_authorities;
COMMIT;
CREATE TABLE public.musicbrainz_artists_clavis_authorities AS
 SELECT a.gid,ca.authority_id FROM musicbrainz_artists a JOIN clavis.authority ca
  on(a.sort_name=ca.sort_text) where ca.authority_type in ('P','E');
DROP TABLE public.musicbrainz_artists;
CREATE INDEX musicbrainz_artists_clavis_authorities_gid_idx ON public.musicbrainz_artists_clavis_authorities(gid);
CREATE INDEX musicbrainz_artists_clavis_authorities_authority_id_idx ON public.musicbrainz_artists_clavis_authorities(authority_id);
