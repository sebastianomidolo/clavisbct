psql -X -q clavisbct_development informhop -f extras/export_to_bctaudio.sql | sed s/\<\\/element\>//g | sed s/\<element\>//g

