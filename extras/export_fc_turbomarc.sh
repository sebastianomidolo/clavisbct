/usr/bin/psql -X -q clavisbct_development informhop -f extras/export_fc_turbomarc.sql

# /usr/bin/psql -X -q clavisbct_development informhop -f extras/export_fc_turbomarc.sql | /bin/sed s/\<\\/element\>//g | /bin/sed s/\<element\>//g


