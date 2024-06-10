SET SEARCH_PATH TO import;

-- TABLE lookup_value
-- create unique index if not exists lookup_value_ndx on lookup_value (value_key,value_language,value_class);
create index if not exists lookup_value_class_ndx on lookup_value (value_class);
create index if not exists lookup_value_language_ndx on lookup_value (value_language);

-- TABLE loan
create index if not exists clavis_loan_item_id_ndx on loan(item_id);
create index if not exists clavis_loan_manifestation_id_ndx on loan(manifestation_id);
create index if not exists loan_patron_id_ndx on loan(patron_id);

-- TABLE l_authority_manifestation_manifestation
create index if not exists l_authority_manifestation_manifestation_id_ndx on l_authority_manifestation (manifestation_id);

-- TABLE authority
create index if not exists clavis_authorities_full_text on authority(full_text);
create index if not exists clavis_authorities_authority_id on authority(authority_id);
create index if not exists clavis_authorities_subject_class on authority(subject_class);
create index if not exists clavis_authorities_authority_type on authority(authority_type);

-- TABLE item
create index if not exists clavis_item_manifestation_id_ndx on item(manifestation_id);
create unique index if not exists item_custom_field3 ON item(custom_field3) WHERE owner_library_id=-1 AND custom_field3 notnull;
create unique index if not exists item_custom_field1 ON item(custom_field1) WHERE owner_library_id=-3 AND custom_field1 notnull;
create index if not exists clavis_item_collocation_idx ON item(collocation);
create index if not exists clavis_item_serieinv_idx on item(inventory_serie_id);
create index if not exists item_owner_library_id_idx ON item(owner_library_id);
create index if not exists item_home_library_id_idx ON item(home_library_id);
create index if not exists item_section_idx ON item("section");
create index if not exists item_specification_idx ON item(specification);
create index if not exists item_supplier_id_idx ON item(supplier_id);
create index if not exists item_barcode_idx ON item(barcode);
create index if not exists item_barcode_item_status_idx ON item(barcode,item_status);
create index if not exists rfid_code_idx ON item(rfid_code);
create index if not exists item_media_type_ndx on item(item_media);
create index if not exists item_status_ndx on item(item_status);
create index if not exists item_title_idx ON item USING gin(to_tsvector('simple', title));


-- TABLE manifestation
create index if not exists manifestation_edition_date on manifestation(edition_date);
create index if not exists ean_clavis_manifestation_ndx on manifestation("EAN") where "EAN"!='';
create index if not exists isbnissn_clavis_manifestation_ndx on manifestation("ISBNISSN") where "ISBNISSN"!='';

