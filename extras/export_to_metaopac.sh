psql -X -q clavisbct_development informhop -f extras/export_to_metaopac.sql | sed s/\<\\/element\>//g | sed s/\<element\>//g

