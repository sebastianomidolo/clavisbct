-- DROP VIEW clavis.view_estrazione_da_magazzino;
CREATE OR REPLACE VIEW clavis.view_estrazione_da_magazzino AS
  select os.item_id,os.os_section,ci.item_status,ist.value_label as item_status_label,
      ci.loan_status, lst.value_label as loan_status_label,ci.section,
      lcl.value_key as loan_class, lcl.value_label as loan_class_label,
      ci.custom_field1,ci.barcode,
   (CASE WHEN os.os_section IN ('CCNC','CCPT') THEN
     vedetta
   ELSE
     r.dewey_collocation
   END)
   as collocazione_scaffale_aperto,
  substr(trim(cm.title),1,60) as titolo,
  cc.collocazione AS collocazione_magazzino
 from open_shelf_items os join ricollocazioni r using (item_id)
   join clavis.collocazioni cc using(item_id)
   join clavis.item ci using(item_id) join clavis.manifestation cm using(manifestation_id)
   join clavis.lookup_value ist on(ist.value_class='ITEMSTATUS' and ist.value_key=ci.item_status
       and ist.value_language='it_IT')
   join clavis.lookup_value lcl on(lcl.value_class='LOANCLASS' and lcl.value_key=ci.loan_class
       and lcl.value_language='it_IT')
   join clavis.lookup_value lst on(lst.value_class='LOANSTATUS' and lst.value_key=ci.loan_status
       and lst.value_language='it_IT');

