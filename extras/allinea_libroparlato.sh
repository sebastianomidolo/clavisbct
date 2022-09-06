#!/bin/sh

### /usr/bin/rsync -avz /home/seb/BCT/wca22014/linux64/LP2mog/upload_libroparlato/ /home/storage/preesistente/libroparlato

(cd /home/ror/bctaudio; RAILS_ENV=development bundle exec /usr/local/bin/rake mdb_export)

# Non allineo libroparlato da aprile 2020 perché la gestione adesso è su ClavisBCT e non più su access
# psql -c "DROP SCHEMA libroparlato CASCADE" clavisbct_development informhop
# pg_dump -n libroparlato -U informhop bctaudio_development | psql clavisbct_development informhop -f -
# (cd /home/ror/clavisbct;psql -f extras/sql/libroparlato_setup.sql clavisbct_development informhop)
# (cd /home/ror/clavisbct; RAILS_ENV=development rake libroparlato_collocazioni | psql clavisbct_development informhop)

psql -c "DROP SCHEMA bm_audiovisivi CASCADE" clavisbct_development informhop
pg_dump -n bm_audiovisivi -U informhop bctaudio_development | psql clavisbct_development informhop -f -
psql -c "DROP SCHEMA bm_letteratura CASCADE" clavisbct_development informhop
pg_dump -n bm_letteratura -U informhop bctaudio_development | psql clavisbct_development informhop -f -
psql -c "DROP SCHEMA bm_periodici CASCADE" clavisbct_development informhop
pg_dump -n bm_periodici -U informhop bctaudio_development | psql clavisbct_development informhop -f -
psql -c "DROP SCHEMA bm_periodici_old CASCADE" clavisbct_development informhop
pg_dump -n bm_periodici_old -U informhop bctaudio_development | psql clavisbct_development informhop -f -

# Commentato il 27 novembre 2017 in quanto mi sembra che il Centro rete non abbia più aggiornato il backup
#psql -c "DROP SCHEMA cr_attrezzature CASCADE" clavisbct_development informhop
#pg_dump -n cr_attrezzature -U informhop bctaudio_development | psql clavisbct_development informhop -f -
#psql -c "DROP SCHEMA cr_acquisti CASCADE" clavisbct_development informhop
#pg_dump -n cr_acquisti -U informhop bctaudio_development | psql clavisbct_development informhop -f -


# 8 gennaio 2014:
(psql -f /home/ror/clavisbct/extras/sql/create_av_manifestations.sql clavisbct_development informhop)

# 10 gennaio 2014 (ma disabilitato 30 aprile 2020 in considerazione del fatto che il sisgema audio musicale non funziona da tempo)
# (cd /home/ror/clavisbct; sh extras/export_to_bctaudio.sh > /home/sites/456.selfip.net/html/export_bctaudio.xml)

# 16 gennaio 2014: (eliminato dal 16 marzo 2016, visto che non veniva usato)
# (cd /home/ror/clavisbct; ./extras/create_musicbrainz_artists_clavis_authorities.sh)

# 1 aprile 2014, eliminato 19 gennaio 2015:
# /bin/rm -rf /home/sites/456.selfip.net/html/clavis/mn
# /usr/bin/wget --quiet -O /dev/stdout http://libroparlato.selfip.net/ProgettiCivica/IntraVedo/html/costellazione_clavis.tar.bz2 | /usr/bin/tar -j -C /home/sites/456.selfip.net/html/clavis -xf -

# Commentato 15 maggio 2020
# (cd /home/ror/clavisbct/extras/libroparlato; /usr/bin/make)

# Questo aggiorna i file audio del libro parlato, ma lo sospendo a maggio 2020
# in attesa di allestire nuove procedure di caricamento dell'audio, in modalità smartworking
# Riattivato sperimentalmente il 23 maggio 2020 e nuovamente disabilitato fine dicembre 2020
# Riattivato 5 gennaio 2021
(cd /home/ror/clavisbct; RAILS_ENV=development rake aggiorna_libroparlato)
