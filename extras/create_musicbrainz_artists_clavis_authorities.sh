psql -X -q -c "\copy artist (gid,sort_name) to /tmp/musicbrainz_artists.csv" musicbrainz_db musicbrainz
psql -X -q -f extras/sql/create_musicbrainz_artists_clavis_authorities.sql clavisbct_development informhop
psql -X -q -f extras/sql/create_musicbrainz_artists_clavis_authorities.sql clavisbct_production informhop

