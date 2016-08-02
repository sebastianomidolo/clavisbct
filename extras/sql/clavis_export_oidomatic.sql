DROP TABLE temp_import_areaonlus, temp_import_sbam, temp_import_librinlinea;

CREATE TABLE temp_import_areaonlus(oid text, isbn text);
CREATE TABLE temp_import_sbam(oid text, isbn text, bid text);
CREATE TABLE temp_import_librinlinea(isbn text, bid char(10));

\copy temp_import_areaonlus   from '/home/seb/2016_05_10_areaonlus.csv' delimiter ';';


-- Per ottenere /tmp/isbn_sbam.csv:
-- cut -d ',' -f 1-3 /home/seb/BCT/wca22014/linux64/librinlinea/Posseduto_SBAM.csv > /tmp/isbn_sbam.csv
\copy temp_import_sbam        from '/tmp/isbn_sbam.csv' delimiter ',';

-- Per ottenere /tmp/librinlinea_bids.csv:
-- cut -d ',' -f 1-2 /home/seb/BCT/wca22014/linux64/librinlinea/Posseduto_to0.csv > /tmp/librinlinea_bids.csv
\copy temp_import_librinlinea from '/tmp/librinlinea_bids.csv' delimiter ',';

UPDATE temp_import_areaonlus set isbn = replace(isbn,'-','');
UPDATE temp_import_areaonlus set isbn = replace(isbn,' ','');

ALTER TABLE temp_import_areaonlus ADD COLUMN bid char(10);
ALTER TABLE temp_import_areaonlus ADD COLUMN manifestation_id integer;
ALTER TABLE temp_import_areaonlus ADD COLUMN sbam_oid char(12);

DELETE FROM temp_import_areaonlus WHERE isbn='' OR isbn='ISBN';
DELETE FROM temp_import_sbam WHERE bid='BID';
DELETE FROM temp_import_librinlinea WHERE bid='BID';
DELETE FROM temp_import_librinlinea WHERE bid ~* '"';

-- All'inizio ho soltanto ISBN come possibile elemento in comune tra areaonlus e gli altri sistemi;
-- pertanto imposto il BID prendendolo dagli altri sistemi, in base alla corrispondenza degli ISBN

-- 1. sistema: BCT
UPDATE temp_import_areaonlus AS t SET bid = cm.bid
   FROM clavis.manifestation cm WHERE t.bid IS NULL AND regexp_replace(cm."ISBNISSN", '-| ','')=t.isbn;
UPDATE temp_import_areaonlus AS t SET bid = cm.bid
   FROM clavis.manifestation cm WHERE t.bid IS NULL AND regexp_replace(cm."EAN", '-| ','')=t.isbn;

-- 2. sistema: Librinlinea
UPDATE temp_import_areaonlus AS t SET bid = ll.bid
   FROM temp_import_librinlinea ll WHERE t.bid IS NULL AND ll.isbn=t.isbn;

-- 3. sistema: SBAM
UPDATE temp_import_areaonlus AS t SET bid = sb.bid
   FROM temp_import_sbam sb WHERE t.bid IS NULL AND sb.isbn=t.isbn;

-- A questo punto ho recuperato tutti i BID recuperabili dai tre sistemi
-- Passo quindi a aggiornare temp_import_areaonlus con manifestation_id (di BCT) e sbam_oid (di SBAM)
UPDATE temp_import_areaonlus AS ao SET manifestation_id=s.manifestation_ID
   FROM clavis.manifestation AS s WHERE ao.manifestation_id IS NULL AND ao.bid=s.bid;

UPDATE temp_import_areaonlus AS ao SET sbam_oid=s.oid
   FROM temp_import_sbam AS s WHERE ao.sbam_oid IS NULL AND ao.bid=s.bid;



-- delete from temp_import_areaonlus where bid is null and manifestation_id is null and sbam_oid is null;



CREATE UNIQUE INDEX temp_import_librinlinea_idx ON temp_import_librinlinea (bid);
CREATE UNIQUE INDEX temp_import_sbam_idx ON temp_import_sbam (bid);

--update temp_import_areaonlus as t set bid = ll.bid
--   from temp_import_librinlinea ll where ll.isbn=t.isbn;


-- esportazione dati per oidomatic
-- bct.csv
\copy (select distinct manifestation_id,bid,2 from clavis.manifestation cm join clavis.item ci using(manifestation_id) where bid_source in ('SBN','SBNBCT') and ci.opac_visible='1' and ci.item_status IN ('F','G','K','V')) to '/home/sites/oidomatic.comperio.it/dataimport/bct/bct.csv' delimiter ','

\copy (select oid,'2:' || manifestation_id from temp_import_areaonlus where manifestation_id notnull) to '/home/sites/oidomatic.comperio.it/dataimport/area_onlus_per_oidomatic.csv' delimiter ','

-- \copy (select oid,bid from temp_import_areaonlus where bid notnull) to '/tmp/area_onlus_per_oidomatic_bid.csv' delimiter ','
\copy (select oid,'5:' || sbam_oid from temp_import_areaonlus where sbam_oid notnull) to '/tmp/area_onlus_per_oidomatic_sbam.csv' delimiter ','

\copy (select oid,bid from temp_import_sbam) to '/home/sites/oidomatic.comperio.it/dataimport/sbam/sbam.csv' delimiter ','


\copy (SELECT DISTINCT ll.bid FROM temp_import_librinlinea ll LEFT JOIN temp_import_sbam sb USING(bid) LEFT JOIN clavis.manifestation cm ON(cm.bid=ll.bid) WHERE (sb.bid notnull OR cm.bid notnull)) TO '/home/sites/oidomatic.comperio.it/dataimport/librinlinea/librinlinea_bids.csv'





