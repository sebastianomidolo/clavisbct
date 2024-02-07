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
 from public.open_shelf_items os join public.ricollocazioni r using (item_id)
   join clavis.collocazioni cc using(item_id)
   join clavis.item ci using(item_id) join clavis.manifestation cm using(manifestation_id)
   join clavis.lookup_value ist on(ist.value_class='ITEMSTATUS' and ist.value_key=ci.item_status
       and ist.value_language='it_IT')
   join clavis.lookup_value lcl on(lcl.value_class='LOANCLASS' and lcl.value_key=ci.loan_class
       and lcl.value_language='it_IT')
   join clavis.lookup_value lst on(lst.value_class='LOANSTATUS' and lst.value_key=ci.loan_status
       and lst.value_language='it_IT');

create or replace view public.serial_details as
 with abb as (
        select t.title,t.serial_list_id,t.id as title_id,s.library_id,
                          array_to_string(array_agg(l.clavis_library_id order by nickname), ',') as libraries,
                          array_to_string(array_agg(s.numero_copie order by nickname), ',') as numero_copie,
                          array_to_string(array_agg(s.prezzo order by nickname), ',') as prezzo_in_fattura,
                          array_to_string(array_agg(s.serial_invoice_id order by nickname), ',') as invoice_ids,
  			  sum(s.numero_copie) as tot_copie,
          array_to_string(array_agg(l.nickname order by nickname), ', ') as library_names
       from public.serial_titles         t
        join public.serial_subscriptions s on (s.serial_title_id=t.id)
            join public.serial_libraries l on (l.clavis_library_id=s.library_id and l.serial_list_id=t.serial_list_id)
       -- where t.serial_list_id=19  AND library_id=3
       group by t.id,s.library_id
     )
    select st.serial_list_id,st.id,cm.manifestation_id,st.title,cm.publisher,
            st.prezzo_stimato*abb.tot_copie as prezzo_totale_stimato,st.prezzo_stimato,
             st.note,st.note_fornitore,abb.libraries,abb.library_names,abb.tot_copie,abb.numero_copie,
	     abb.prezzo_in_fattura,abb.invoice_ids,
             public.serial_frequency_of_issue(cm.unimarc::xml) as frequency_code, freq.label as frequency_label,
             array_agg(i.item_id order by issue_year desc, issue_number desc) as item_ids,
             array_agg(i.issue_arrival_date order by issue_year desc, issue_number desc) as issue_arrival_dates,
             array_agg(i.issue_arrival_date_expected order by issue_year desc, issue_number desc) as issue_arrival_dates_expected,
	     array_agg(i.issue_description order by issue_year desc, issue_number desc) as issue_descriptions,
	     array_agg(issue_status_label order by issue_year desc, issue_number desc) as issue_status
            from public.serial_titles st
	    join abb on(abb.title_id=st.id)
            left join public.serial_invoices si on(si.clavis_invoice_id::text=abb.invoice_ids)
            left join clavis.manifestation cm on(cm.manifestation_id=st.manifestation_id)
            left join lateral
 (

select i.manifestation_id,i.item_id,i.issue_year,i.issue_number,
   to_char(issue_arrival_date, 'dd-mm-yyyy') as issue_arrival_date,
   to_char(issue_arrival_date_expected, 'dd-mm-yyyy') as issue_arrival_date_expected,
   i.issue_description,
   i.issue_status as issue_status_label
     from clavis.item i
   where i.manifestation_id=st.manifestation_id AND home_library_id=abb.library_id
    and i.issue_year is not null
     order by i.issue_year desc, i.issue_number desc
    limit 6

) as i on i.manifestation_id=cm.manifestation_id
	    left join clavis.unimarc_codes freq
        on(freq.code_value::char=public.serial_frequency_of_issue(cm.unimarc::xml)
             and freq.language='it_IT' and freq.field_number = 110 and freq.pos=1)
          
	group by st.id,cm.manifestation_id,abb.tot_copie,abb.libraries,abb.library_names,abb.numero_copie,
	       abb.prezzo_in_fattura,abb.invoice_ids,freq.label
            order by st.sortkey, lower(st.title);

-- DROP VIEW sbct_acquisti.pac_collocazione_dewey;
CREATE OR REPLACE VIEW sbct_acquisti.pac_collocazione_dewey as
select cm.manifestation_id,
split_part(ca1.full_text, ' ', 1) as dewey, ca1.authority_id as dewey_id,
   case when ca2.authority_id is null then split_part(cm2.sort_text, ' ', 1) else ca2.sort_text end as main_entry,

ca2.authority_id as main_entry_id, lam2.link_type
 from clavis.manifestation cm
   left join clavis.l_authority_manifestation lam1 on(lam1.manifestation_id=cm.manifestation_id and lam1.link_type=676)
   left join clavis.l_authority_manifestation lam2 on(lam2.manifestation_id=cm.manifestation_id and lam2.link_type=700)
   left join clavis.authority ca1 on(ca1.authority_id=lam1.authority_id)
   left join clavis.authority ca2 on(ca2.authority_id=lam2.authority_id)
   left join clavis.manifestation cm2 on(cm2.manifestation_id=cm.manifestation_id);


CREATE OR REPLACE VIEW public.view_services as
WITH RECURSIVE tree_view AS (
  SELECT id, parent_id, name, visible, 0 AS level,
      CAST(name AS text) AS order_sequence,
      id as root_id
    FROM public.services
UNION ALL
  SELECT parent.id, parent.parent_id, parent.name, parent.visible, level + 1 AS level,
         CAST(order_sequence || '_' || CAST(parent.name AS TEXT) AS TEXT) AS order_sequence,
	 root_id
    FROM public.services parent JOIN tree_view tv ON parent.parent_id = tv.id
)
SELECT root_id,id,level,name, visible, order_sequence FROM tree_view;

create or replace view clavis.view_notifications
as
select notification_id,notification_state,notification_channel,notification_class,
n_state.value_label as n_state,
n_channel.value_label as n_channel,
n_class.value_label as n_class,
object_class,
object_id,sender_library_id,delivery_date,acknowledge_date,internal_status,
date_created,date_updated,notes
FROM clavis.last_notifications n
   join clavis.lookup_value n_channel on(n_channel.value_class='NOTIFICATIONCHANNEL' and n_channel.value_key=notification_channel)
   join clavis.lookup_value n_class on(n_class.value_class='NOTIFICATIONCLASS' and n_class.value_key=notification_class)
   join clavis.lookup_value n_state on(n_state.value_class='NOTIFICATIONSTATE' and n_state.value_key=notification_state)
   where n_channel.value_language='it_IT'
     and n_class.value_language=n_channel.value_language
     and n_state.value_language=n_channel.value_language;
