
SET SEARCH_PATH TO import;

set standard_conforming_strings to false;
set backslash_quote to 'safe_encoding';

-- Testi (105) Campo codificato unimarc 105
-- vedi http://unimarc-it.wikidot.com/105
-- create table if not exists uni105_4 as select manifestation_id,public.unimarc_105(unimarc::xml,4)::char(1) from manifestation;
-- TABLE uni105_4
-- create index if not exists uni105_4_manifestation_id_ndx on uni105_4(manifestation_id);
-- create index if not exists uni105_4_unimarc_105_ndx on uni105_4(unimarc_105);


-- create table if not exists uni105_11 as select manifestation_id,public.unimarc_105(unimarc::xml,11)::char(1) from manifestation;
-- create index if not exists uni105_11_manifestation_id_ndx on uni105_11(manifestation_id);
-- create index if not exists uni105_11_unimarc_105_ndx on uni105_11(unimarc_105);


-- 10 giugno 2024: le due tabelle di supporto uni105_4 e uni105_11 vanno sostituite da questa che le comprende entrambe:
create table if not exists uni105 as select manifestation_id,
          public.unimarc_105(unimarc::xml,4)::char(1)  as u105_4,
          public.unimarc_105(unimarc::xml,11)::char(1) as u105_11,
          public.unimarc_100(unimarc::xml,17,3)::char(3) as u100_pubblico
	  from manifestation;

create index if not exists uni105_manifestation_id_ndx on uni105(manifestation_id);
create index if not exists uni105_u105_4_ndx  on uni105(u105_4);
create index if not exists uni105_u105_11_ndx on uni105(u105_11);
create index if not exists uni105_u105_pubblico_ndx on uni105(u100_pubblico);


