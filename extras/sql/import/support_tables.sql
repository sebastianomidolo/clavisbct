
SET SEARCH_PATH TO import;

set standard_conforming_strings to false;
set backslash_quote to 'safe_encoding';

-- Testi (105) Campo codificato unimarc 105
-- vedi http://unimarc-it.wikidot.com/105
create table if not exists uni105_4 as select manifestation_id,public.unimarc_105(unimarc::xml,4)::char(1) from manifestation;
-- TABLE uni105_4
create index if not exists uni105_4_manifestation_id_ndx on uni105_4(manifestation_id);
create index if not exists uni105_4_unimarc_105_ndx on uni105_4(unimarc_105);


create table if not exists uni105_11 as select manifestation_id,public.unimarc_105(unimarc::xml,11)::char(1) from manifestation;
create index if not exists uni105_11_manifestation_id_ndx on uni105_11(manifestation_id);
create index if not exists uni105_11_unimarc_105_ndx on uni105_11(unimarc_105);


-- sarebbe meglio così:
create table if not exists uni105 as select manifestation_id,
          public.unimarc_105(unimarc::xml,4)::char(1)  as u105_4,
          public.unimarc_105(unimarc::xml,11)::char(1) as u105_11 from manifestation;

create index if not exists uni105_manifestation_id_ndx on uni105(manifestation_id);
create index if not exists uni105_unimarc_105_4_ndx  on uni105(u105_4);
create index if not exists uni105_unimarc_105_11_ndx on uni105(u105_11);


