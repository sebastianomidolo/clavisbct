SET SEARCH_PATH TO sbct_acquisti
;
set standard_conforming_strings to false;
set backslash_quote to 'safe_encoding';

select now() as "Inizio creazione tabella sbct_acquisti.acquisition_time";

drop table if exists acquisition_time;

create table acquisition_time as select * from view_acquisition_time;

create unique index acquisition_time_id_copia_idx on acquisition_time(id_copia);

--alter table acquisition_time add primary key co.id_copia;

select now() as "Fine creazione tabella sbct_acquisti.acquisition_time";



