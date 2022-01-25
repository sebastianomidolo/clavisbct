-- Nati per leggere 2020 - dati richiesti da Gabriella Carré
-- Vedi scratchpad.txt nota 11 giugno 2018
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
  (2020,'2020-01-01','2020-12-31','2015-01-01','2020-12-31','2020-01-01','2020-12-31','2020-12-31')
  -- (2020,'2019-01-01','2019-12-31','2015-01-01','2020-12-31','2020-01-01','2020-12-31','2020-12-31')
  ;

create temp table npl_libraries as
select label as biblioteca,library_id from clavis.library where library_id in
 (2, 3, 4, 5, 7, 8, 10, 11, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 27, 29, 30, 496, 1121);

----- Non modificare dopo questa linea

create temp table npl_iscrittibimbi as
  select patron_id from clavis.patron p join npl_libraries l on(l.library_id=p.registration_library_id)
  where birth_date between
    (select birth_date_from from npl_config) and
    (select birth_date_to from npl_config)     
  and date_created <= (select patron_date_created_less_or_equal from npl_config);


select count(*) as "Numero totale di libri RN01-RN06" 
  from clavis.item ci join npl_libraries l on(l.library_id=ci.home_library_id)
 where section='RN' and (collocation ~ '^0[12346]')
    and item_status in('B','F','G','K','R','S','V','X','Y');

select count(*) as "Numero di libri RN01-RN06 acquisiti", inventory_date_from as "dal", inventory_date_to as "al"
  from clavis.item ci join npl_libraries l on(l.library_id=ci.home_library_id)
    left join npl_config on(true)
 where section='RN' and (collocation ~ '^0[12346]')
    and item_status in('B','F','G','K','R','S','V','X','Y')
    and inventory_date between inventory_date_from and inventory_date_to
    group by inventory_date_from,inventory_date_to;


select count(*) as "Numero iscritti", patron_date_created_less_or_equal as "fino al",
    birth_date_from as "nati dal", birth_date_to as "al"
  from npl_iscrittibimbi
   join npl_config on(true)
  group by patron_date_created_less_or_equal,birth_date_from, birth_date_to;


select count(*) as "Numero prestiti", loan_date_begin_from as "Dalla data", loan_date_begin_to as "Alla data"
  FROM clavis.loan cl join npl_iscrittibimbi b using(patron_id)
  join npl_libraries l on(l.library_id=cl.from_library)
  left join npl_config on(true)
  where loan_date_begin between
    (select loan_date_begin_from from npl_config) and
    (select loan_date_begin_to from npl_config)
    group by loan_date_begin_from, loan_date_begin_to;


