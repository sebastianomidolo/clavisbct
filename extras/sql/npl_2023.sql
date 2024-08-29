-- Nati per leggere 2023 - dati richiesti da Susanna Bassi a Dorina via email 

/* Esempio di uso da psql:

\o /home/storage/preesistente/static/npl_2023.txt
\i /home/ror/clavisbct/extras/sql/npl_2023.sql
\o
Accesso da browser web:
https://bctwww.comperio.it/static/npl_2023.txt

*/

create temp table npl_config (
   year integer,
   inventory_date_from date,
   inventory_date_to date,
   birth_date_from date,
   birth_date_to date,
   loan_date_begin_from date,
   loan_date_begin_to date,
   patron_date_created_less_or_equal date
);
insert into npl_config
  (year,inventory_date_from, inventory_date_to,birth_date_from, birth_date_to, loan_date_begin_from, loan_date_begin_to,
           patron_date_created_less_or_equal) values
  (2023,'2023-01-01','2023-12-31','2018-01-01','2023-12-31','2023-01-01','2023-12-31','2023-12-31')
-- (2022,'2022-01-01','2022-12-31','2017-01-01','2022-12-31','2022-01-01','2022-12-31','2022-12-31')
  -- (2021,'2019-01-01','2019-12-31','2015-01-01','2021-12-31','2021-01-01','2021-12-31','2021-12-31')
  ;


----- Non modificare dopo questa linea

create temp table npl_libraries as
select cl.label as biblioteca,cl.library_id
   from clavis.library cl
    join sbct_acquisti.library_codes lc on(lc.clavis_library_id=cl.library_id)
    where lc.owner='bct';


create temp table npl_iscrittibimbi as
  select p.patron_id,date_part('year', date_created) as year from clavis.patron p join npl_libraries l on(l.library_id=p.registration_library_id)
  where birth_date between
    (select birth_date_from from npl_config) and
    (select birth_date_to from npl_config)     
  and date_created <= (select patron_date_created_less_or_equal from npl_config);


select count(*) as "Numero totale di libri RN01-RN05" 
  from clavis.item ci join npl_libraries l on(l.library_id=ci.home_library_id)
 where section='RN' and (collocation ~ '^0[12345]')
    and item_status in('B','F','G','K','R','S','V','X','Y');

select count(*) as "Numero di libri RN01-RN05 acquisiti", inventory_date_from as "dal", inventory_date_to as "al"
  from clavis.item ci join npl_libraries l on(l.library_id=ci.home_library_id)
    left join npl_config on(true)
 where section='RN' and (collocation ~ '^0[12345]')
    and item_status in('B','F','G','K','R','S','V','X','Y')
    and inventory_date between inventory_date_from and inventory_date_to
    group by inventory_date_from,inventory_date_to;


select count(*) as "Numero iscritti in totale", patron_date_created_less_or_equal as "fino al",
    birth_date_from as "nati dal", birth_date_to as "al"
  from npl_iscrittibimbi
   join npl_config on(true)
  group by patron_date_created_less_or_equal,birth_date_from, birth_date_to;

select count(*) as "Numero iscritti", npl_config.year as "Anno iscrizione",
    birth_date_from as "nati dal", birth_date_to as "al"
  from npl_iscrittibimbi
   join npl_config on(true)
   where npl_iscrittibimbi.year=npl_config.year
  group by npl_config.year,birth_date_from, birth_date_to;


select count(*) as "Numero prestiti", loan_date_begin_from as "Dalla data", loan_date_begin_to as "Alla data"
  FROM clavis.loan cl join npl_iscrittibimbi b using(patron_id)
  join npl_libraries l on(l.library_id=cl.from_library)
  left join npl_config on(true)
  where loan_date_begin between
    (select loan_date_begin_from from npl_config) and
    (select loan_date_begin_to from npl_config)
    group by loan_date_begin_from, loan_date_begin_to;

select * from npl_libraries order by biblioteca;

