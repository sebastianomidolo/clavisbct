#!/bin/sh

(cd /home/ror/bctaudio; RAILS_ENV=production  /usr/local/bin/rake mdb_export)
(cd /home/ror/bctaudio; RAILS_ENV=development /usr/local/bin/rake mdb_export)

psql -c "DROP SCHEMA libroparlato CASCADE" clavisbct_production informhop
pg_dump -n libroparlato -U informhop bctaudio_production | psql clavisbct_production informhop -f -
(cd /home/ror/clavisbct;psql -f extras/sql/libroparlato_setup.sql clavisbct_production informhop)
(cd /home/ror/clavisbct; RAILS_ENV=production rake libroparlato_collocazioni | psql clavisbct_production informhop)

psql -c "DROP SCHEMA libroparlato CASCADE" clavisbct_development informhop
pg_dump -n libroparlato -U informhop bctaudio_development | psql clavisbct_development informhop -f -
(cd /home/ror/clavisbct;psql -f extras/sql/libroparlato_setup.sql clavisbct_development informhop)
(cd /home/ror/clavisbct; RAILS_ENV=development rake libroparlato_collocazioni | psql clavisbct_development informhop)

psql -c "DROP SCHEMA bm_audiovisivi CASCADE" clavisbct_production informhop
pg_dump -n bm_audiovisivi -U informhop bctaudio_production | psql clavisbct_production informhop -f -
psql -c "DROP SCHEMA bm_letteratura CASCADE" clavisbct_production informhop
pg_dump -n bm_letteratura -U informhop bctaudio_production | psql clavisbct_production informhop -f -
psql -c "DROP SCHEMA cr_attrezzature CASCADE" clavisbct_production informhop
pg_dump -n cr_attrezzature -U informhop bctaudio_production | psql clavisbct_production informhop -f -
psql -c "DROP SCHEMA cr_acquisti CASCADE" clavisbct_production informhop
pg_dump -n cr_acquisti -U informhop bctaudio_production | psql clavisbct_production informhop -f -


psql -c "DROP SCHEMA bm_audiovisivi CASCADE" clavisbct_development informhop
pg_dump -n bm_audiovisivi -U informhop bctaudio_development | psql clavisbct_development informhop -f -
psql -c "DROP SCHEMA bm_letteratura CASCADE" clavisbct_development informhop
pg_dump -n bm_letteratura -U informhop bctaudio_development | psql clavisbct_development informhop -f -
psql -c "DROP SCHEMA cr_attrezzature CASCADE" clavisbct_development informhop
pg_dump -n cr_attrezzature -U informhop bctaudio_development | psql clavisbct_development informhop -f -
psql -c "DROP SCHEMA cr_acquisti CASCADE" clavisbct_development informhop
pg_dump -n cr_acquisti -U informhop bctaudio_development | psql clavisbct_development informhop -f -

# 8 gennaio 2014:
(psql -f /home/ror/clavisbct/extras/sql/create_av_manifestations.sql clavisbct_development informhop)
(psql -f /home/ror/clavisbct/extras/sql/create_av_manifestations.sql clavisbct_production informhop)

# 10 gennaio 2014:
(cd /home/ror/clavisbct; sh extras/export_to_bctaudio.sh > /home/sites/456.selfip.net/html/export_bctaudio.xml)

# 16 gennaio 2014:
(cd /home/ror/clavisbct; ./extras/create_musicbrainz_artists_clavis_authorities.sh)

# 1 aprile 2014:
/bin/rm -rf /home/sites/456.selfip.net/html/clavis/mn
/usr/bin/wget --quiet -O /dev/stdout http://libroparlato.selfip.net/ProgettiCivica/IntraVedo/html/costellazione_clavis.tar.bz2 | /usr/bin/tar -j -C /home/sites/456.selfip.net/html/clavis -xf -

