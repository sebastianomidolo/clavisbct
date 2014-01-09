# Alla fine: zip export_per_metaopac.zip export_per_metaopac.xml
psql -X -q clavisbct_development informhop -f extras/export_to_metaopac.sql | sed s/\<\\/element\>//g | sed s/\<element\>//g

