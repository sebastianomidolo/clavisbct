SET SEARCH_PATH TO sbct_acquisti;

set standard_conforming_strings to false;
set backslash_quote to 'safe_encoding';

DROP VIEW IF EXISTS view_acquisition_time;

CREATE OR REPLACE VIEW view_acquisition_time 


AS
select co.id_titolo,
co.id_copia,
co.id_ordine,
co.order_id,
ord.order_date::date as ord_dataordine,
substr(ord.label,1,20) as descr_ordine,
co.supplier_id,
sup.supplier_name as fornitore,
co.data_arrivo,
co.data_arrivo       - ord.order_date::date   as tempo_di_attesa,

CASE when co.data_arrivo       - ord.order_date::date between  '0' and '60'  then 'verde'
   when co.data_arrivo       - ord.order_date::date between  '61' and '120'  then 'arancione'
   else 'rosso'
   
end as  monitoraggio 



FROM copie as co
JOIN orders as ord ON (co.order_id=ord.order_id)
JOIN suppliers as sup ON (co.supplier_id=sup.supplier_id)

where co.order_id is not null and co.order_status='A' and co.data_arrivo is not null and co.supplier_id IN ('154','384','503')
      and ord.order_date::date > '2022-01-01'
order by co.supplier_id, co.order_id;


