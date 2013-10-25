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

# Aggiunta del 15 ottobre 2013
psql -c "DROP SCHEMA bm_audiovisivi CASCADE" clavisbct_production informhop
pg_dump -n bm_audiovisivi -U informhop bctaudio_production | psql clavisbct_production informhop -f -
psql -c "DROP SCHEMA bm_letteratura CASCADE" clavisbct_production informhop
pg_dump -n bm_letteratura -U informhop bctaudio_production | psql clavisbct_production informhop -f -

psql -c "DROP SCHEMA bm_audiovisivi CASCADE" clavisbct_development informhop
pg_dump -n bm_audiovisivi -U informhop bctaudio_development | psql clavisbct_development informhop -f -
psql -c "DROP SCHEMA bm_letteratura CASCADE" clavisbct_development informhop
pg_dump -n bm_letteratura -U informhop bctaudio_development | psql clavisbct_development informhop -f -
