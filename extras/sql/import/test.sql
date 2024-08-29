-- Ho messo qui questa vista, ma è solo una prova
create or replace view import.classifiche as
(
select item_id, item_media_label, home_library,title, prestiti, pubblico, rn
FROM (
    SELECT item_id,home_library,substr(title,1,50) as title, prestiti, pubblico,
       item_media_label,
        ROW_NUMBER() OVER (PARTITION BY home_library ORDER BY prestiti DESC) AS rn
    FROM import.super_items
) AS ranked_loans
WHERE rn <= 10
and home_library notnull
and prestiti > 0
);
