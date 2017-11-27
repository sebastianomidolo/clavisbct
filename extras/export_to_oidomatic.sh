cut -d ',' -f 1-2 /home/storage/nowww/librinlinea/Posseduto_to0.csv > /tmp/librinlinea_bids.csv
cut -d ',' -f 1-3 /home/storage/nowww/librinlinea/Posseduto_SBAM.csv > /tmp/isbn_sbam.csv

# /usr/bin/psql -X -q clavisbct_development informhop -f extras/sql/clavis_export_oidomatic.sql
/usr/bin/psql -X clavisbct_development informhop -f extras/sql/clavis_export_oidomatic.sql
