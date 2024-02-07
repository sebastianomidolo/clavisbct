CREATE OR REPLACE VIEW sbct_acquisti.pac_roles AS
  select id as role_id, name from public.roles where name ~ '^Acquisition' or name ~ '^Event';


CREATE OR REPLACE VIEW sbct_acquisti.pac_users AS
  select distinct u.id as user_id, cl.name, cl.lastname, cl.default_library_id as library_id,
     cl.username, l.shortlabel as library_name
      from public.users u
       join public.roles_users ru on(ru.user_id=u.id)
       join sbct_acquisti.pac_roles r using(role_id)
       join clavis.librarian cl on (cl.username=u.email)
       join clavis.library l on(l.library_id=cl.default_library_id);
      


CREATE OR REPLACE VIEW sbct_acquisti.vcopie AS
-- select id_copia,id_titolo,library_id,lc.label as siglabct,order_status as status,c.data_arrivo,
--   c.supplier_id,prezzo,c.order_id,clavis_item_id, ci.item_status, ci.item_source, ci.inventory_date
--   from sbct_acquisti.copie c join sbct_acquisti.library_codes lc on (lc.clavis_library_id=c.library_id)
--   left join clavis.item ci on(ci.item_id=c.clavis_item_id);
 select id_copia,id_titolo,
   case when c.home_library_id is not null then c.home_library_id else c.library_id end as library_id,
   case when c.home_library_id is not null then lc2.label else lc1.label end as siglabct,
    order_status as status,c.data_arrivo,
   c.supplier_id,prezzo,c.order_id,clavis_item_id, ci.item_status, ci.item_source, ci.inventory_date
   FROM sbct_acquisti.copie c
    left join sbct_acquisti.library_codes lc1 on (lc1.clavis_library_id=c.library_id)
    left join sbct_acquisti.library_codes lc2 on (lc2.clavis_library_id=c.home_library_id)
    left join clavis.item ci on(ci.item_id=c.clavis_item_id);



CREATE OR REPLACE VIEW public.pac_budgets as
select b.budget_id,b.label, cl.label as library_name,lc.label as siglabct, cl.library_id,b.clavis_budget_id,bl.quota,
  bl.subquota,
  cb.total_amount,b.locked,b.supplier_id,
  round((b.total_amount/100*bl.quota),2) as partial_amount,
  round((round((b.total_amount/100*bl.quota),2) / 100*bl.subquota),2) as subquota_amount,
  100-subquota as quota_percent
 from sbct_acquisti.budgets b
   left join sbct_acquisti.l_budgets_libraries bl using(budget_id)
   left join clavis.budget cb on (cb.budget_id = b.clavis_budget_id)
   left join sbct_acquisti.library_codes lc using(clavis_library_id)
   join clavis.library cl on (cl.library_id=bl.clavis_library_id);


create or replace view sbct_acquisti.proposte_acquisto_details
as 

select cpp.proposal_id,cpp.patron_id,
cpp.author,cpp.title,cpp.publisher,cpp.year,cpp.notes,cpp.librarian_notes,cpp.status,cpp.ean,cpp.rda,cpp.item_id,
cpp.proposal_date,cpp.date_created,cpp.date_updated,cpp.created_by,cpp.modified_by,cpp.sbct_title_id,
lv.value_label as stato_proposta,cp.barcode as patron_barcode,cl.library_id, lc.label as preferred_library,
    lc2.label as destbib,
    ci.inventory_date,
    ci.item_status,
    titoli.titolo, titoli.id_titolo,copie.id_copia,copie.data_arrivo,ci.home_library_id,copie.date_created as data_inserimento_pac,
    lv2.value_label as item_status_label,
    ci.loan_class,
    ci.manifestation_id,
    trim(cm.title::text) as manifestation_title,
    ci.item_id as clavis_item_id

FROM clavis.purchase_proposal cpp
    left join sbct_acquisti.l_clavis_purchase_proposals_titles ppt using(proposal_id)
    left join sbct_acquisti.copie using(id_titolo)
    left join sbct_acquisti.titoli using(id_titolo)
    left join clavis.lookup_value lv ON(lv.value_key=cpp.status AND lv.value_class = 'PROPOSALSTATUS' AND lv.value_language='it_IT')
    join clavis.patron cp using(patron_id)
    join clavis.library cl on (cl.library_id=cp.preferred_library_id)
    left join sbct_acquisti.library_codes lc on(lc.clavis_library_id=cl.library_id)
    left join clavis.item ci on (ci.manifestation_id=titoli.manifestation_id)
    left join clavis.manifestation cm on (cm.manifestation_id=titoli.manifestation_id)
    left join clavis.lookup_value lv2 ON(lv2.value_key = ci.item_status AND lv2.value_class = 'ITEMSTATUS' AND lv2.value_language='it_IT')
    left join sbct_acquisti.library_codes lc2 on(lc2.clavis_library_id=ci.home_library_id)
;

-- 22 marzo 2023
CREATE OR REPLACE VIEW sbct_acquisti.pac_manifestations AS
  select cm.manifestation_id,cm.title,cm.author,cm."ISBNISSN" as m_isbn,cm."EAN" as m_ean,
     t.id_titolo,t.titolo,t.ean, t.isbn
  from clavis.manifestation cm
    left join sbct_acquisti.titoli t using(manifestation_id);
  



create or replace view sbct_acquisti.proposte_acquisto
as 

select cpp.proposal_id,cpp.patron_id,cpp.author,cpp.title,cpp.publisher,cpp.year,cpp.notes,cpp.librarian_notes,cpp.status,cpp.ean,cpp.rda,cpp.item_id,
cpp.proposal_date,cpp.date_created,cpp.date_updated,cpp.created_by,cpp.modified_by,cpp.sbct_title_id,
lv.value_label as stato_proposta,cp.barcode as patron_barcode,
cm.manifestation_id,titoli.id_titolo,
-- cl.library_id,
lc.label as preferred_library,
-- lc2.label as destbib,
    array_agg(distinct ci.item_status) as item_status,
    array_agg(distinct ci.loan_class) as item_loanclass,
    array_to_string(array_agg(distinct lv2.value_label),',') as item_status_label

FROM clavis.purchase_proposal cpp
    left join sbct_acquisti.l_clavis_purchase_proposals_titles ppt using(proposal_id)
    left join sbct_acquisti.copie using(id_titolo)
    left join sbct_acquisti.titoli using(id_titolo)
    left join clavis.lookup_value lv ON(lv.value_key=cpp.status AND lv.value_class = 'PROPOSALSTATUS' AND lv.value_language='it_IT')
    join clavis.patron cp using(patron_id)
    join clavis.library cl on (cl.library_id=cp.preferred_library_id)
    left join sbct_acquisti.library_codes lc on(lc.clavis_library_id=cl.library_id)
    left join clavis.item ci on (ci.manifestation_id=titoli.manifestation_id)
    left join clavis.manifestation cm on (cm.manifestation_id=titoli.manifestation_id)
    left join clavis.lookup_value lv2 ON(lv2.value_key = ci.item_status AND lv2.value_class = 'ITEMSTATUS' AND lv2.value_language='it_IT')
    left join sbct_acquisti.library_codes lc2 on(lc2.clavis_library_id=ci.home_library_id)
group by

cpp.proposal_id,cpp.patron_id,cpp.author,cpp.title,cpp.publisher,cpp.year,cpp.notes,cpp.librarian_notes,cpp.status,cpp.ean,cpp.rda,cpp.item_id,
cpp.proposal_date,cpp.date_created,cpp.date_updated,cpp.created_by,cpp.modified_by,cpp.sbct_title_id,
stato_proposta,patron_barcode,
-- cl.library_id,
preferred_library, cm.manifestation_id, titoli.id_titolo
;

CREATE OR REPLACE VIEW public.pac_titles as
 select t.id_titolo,cm.manifestation_id,cm.bib_level,cm.manifestation_status,cm.date_created as cm_date_created from sbct_acquisti.titoli t
   join clavis.manifestation cm using(manifestation_id);
   

CREATE OR REPLACE VIEW public.pac_items as
  select case when home_library_id is null then library_id else home_library_id end as library_id,id_copia,
    id_titolo,numcopie,order_status,prezzo,order_id
     from sbct_acquisti.copie;


/*
CREATE OR REPLACE VIEW public.pac_lists as
WITH RECURSIVE tree_view AS (

  SELECT id_lista, parent_id, label, 0 AS level,
      CAST(label AS text) AS order_sequence,
      id_lista as root_id
    FROM sbct_acquisti.liste
    -- WHERE parent_id IS NULL

UNION ALL

  SELECT parent.id_lista, parent.parent_id, parent.label, level + 1 AS level,
         CAST(order_sequence || '_' || CAST(parent.label AS TEXT) AS TEXT) AS order_sequence,
	 root_id
    FROM sbct_acquisti.liste parent JOIN tree_view tv ON parent.parent_id = tv.id_lista
)

SELECT root_id,id_lista,level,label, order_sequence FROM tree_view;
*/

CREATE OR REPLACE VIEW public.pac_lists as
WITH RECURSIVE tree_view AS (

  SELECT id_lista, hidden, owner_id, parent_id, label, 0 AS level,
      CAST(label AS text) AS order_sequence,
      id_lista as root_id
    FROM sbct_acquisti.liste
    -- WHERE parent_id IS NULL

UNION ALL

  SELECT parent.id_lista, parent.hidden, parent.owner_id, parent.parent_id, parent.label, level + 1 AS level,
         CAST(order_sequence || '_' || CAST(parent.label AS TEXT) AS TEXT) AS order_sequence,
	 root_id
    FROM sbct_acquisti.liste parent JOIN tree_view tv ON parent.parent_id = tv.id_lista
)

SELECT root_id,id_lista,hidden,owner_id,level,label, order_sequence FROM tree_view;


create or replace view public.vedi_mic as
select c.*,b.label as budget_label
 from sbct_acquisti.copie c JOIN sbct_acquisti.budgets b on(b.budget_id=c.budget_id);


CREATE OR REPLACE VIEW sbct_acquisti.pac_importi_assegnabili as
with t1 as
(
 select b.budget_id,sum(cp.prezzo * cp.numcopie) as importo
   from  sbct_acquisti.budgets b left join sbct_acquisti.copie cp using(budget_id)
     where
--   budget_id = 37 and
     (cp.order_status IN ('A','O') OR (cp.order_status ='S' AND cp.supplier_id is not null))
     group by b.budget_id
)
select b.budget_id,b.total_amount,
   CASE
   WHEN t1 is null THEN
     b.total_amount
   ELSE
     CASE
       WHEN (b.total_amount - t1.importo) < 0 THEN 0
       ELSE b.total_amount - t1.importo
     END
   END as assegnabile
 FROM sbct_acquisti.budgets b left join t1 using(budget_id);


-- Aggiunte 11 ottobre 2023:
--     sbct_acquisti.pac_multibudget_suppliers
--     sbct_acquisti.pac_suppliers
-- drop view sbct_acquisti.pac_multibudget_suppliers cascade;
create or replace view sbct_acquisti.pac_multibudget_suppliers as
with t1 as
(
 select cb.budget_title,sum(b.total_amount) as total_amount,count(cb) as num_budgets
  from sbct_acquisti.budgets b join clavis.budget cb on(cb.budget_id = b.clavis_budget_id)
   group by cb.budget_title
)
select t1.budget_title as multibudget_label, t1.total_amount as multibudget_importo,t1.num_budgets,
    s.supplier_id from t1 left join  sbct_acquisti.suppliers s
    on s.supplier_name ~ t1.budget_title;

create or replace view sbct_acquisti.pac_suppliers as
with t1 as
(
  select multibudget_label, multibudget_importo, count(supplier_id) as num_suppliers,
    case
     when count(supplier_id) < 1
     then 0
     else round(multibudget_importo/count(supplier_id),2)
    end as quota_fornitore
    from sbct_acquisti.pac_multibudget_suppliers
   group by multibudget_label,multibudget_importo

)
select * from t1 left join  sbct_acquisti.suppliers s
    on s.supplier_name ~ t1.multibudget_label;

