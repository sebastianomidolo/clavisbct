/usr/bin/psql -X -q clavisbct_development informhop -f extras/sql/clavis_export_metaopac.sql
/usr/bin/psql -X -q clavisbct_development informhop -f extras/export_to_metaopac.sql | /bin/sed s/\<\\/element\>//g | /bin/sed s/\<element\>//g > /home/storage/wwwcache/export_metaopac/export_per_metaopac.xml

cd /home/storage/wwwcache/export_metaopac
/bin/rm -f export_per_metaopac.zip
/usr/bin/zip export_per_metaopac.zip export_per_metaopac.xml
