/* Tabelle di supporto per l'esportazione xml per metaopac (31 ottobre 2013) */

CREATE TABLE clavis.export_authorities AS
SELECT cm.manifestation_id,
  array_agg(xmlelement(name link,
     xmlattributes(lam.link_type as tag, a.bid as vid, a.authority_type),
     xmlforest(a.full_text as authority))) as links
   from clavis.manifestation cm
       join clavis.l_authority_manifestation lam on(lam.manifestation_id=cm.manifestation_id)
       join clavis.authority a using(authority_id)
   group by cm.manifestation_id;
CREATE INDEX export_authorities_idx on clavis.export_authorities(manifestation_id);

CREATE TABLE clavis.export_copie AS
select cm.manifestation_id,
  array_agg(xmlelement(name copia, xmlattributes(l.ill_code as library),
   xmlforest(ci.section || '.' || ci.collocation as colloc,
             ci.inventory_serie_id || '-' || ci.inventory_number as invent))) as copie
 from clavis.manifestation cm
       join clavis.item ci ON(cm.manifestation_id=ci.manifestation_id
             AND ci.opac_visible='1'
             AND ci.item_status IN ('F','G','K','V'))
       join clavis.library l on(l.library_id=ci.owner_library_id)
 group by cm.manifestation_id;
CREATE INDEX export_copie_idx on clavis.export_copie(manifestation_id);

CREATE INDEX l_manifestation_idx on clavis.l_manifestation(link_type,manifestation_id_down);
CREATE TABLE clavis.export_collane AS
select cm.manifestation_id,
   array_agg(xmlelement(name title,
      xmlattributes(lm.manifestation_id_up as id, trim(lm.link_sequence) as seq))) as linked_titles
   from clavis.manifestation cm
       join clavis.l_manifestation lm on(lm.link_type=410
                 and lm.manifestation_id_down=cm.manifestation_id)
       where cm.bib_level='c'
   group by cm.manifestation_id;
CREATE INDEX export_collane_idx on clavis.export_collane(manifestation_id);

