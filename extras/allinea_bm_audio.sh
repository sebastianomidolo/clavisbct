#!/bin/sh

(psql -q -X -f /home/seb/BCT/wca22014/bm_audio/dir_scan_output.sql clavisbct_development informhop)
(psql -q -X -f /home/seb/BCT/wca22014/bm_audio/dir_scan_output.sql clavisbct_production informhop)
