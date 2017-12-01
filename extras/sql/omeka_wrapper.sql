DROP SCHEMA bcteka CASCADE;
CREATE SCHEMA bcteka;
set search_path to bcteka;

CREATE FOREIGN TABLE collections (
  id integer,
  "public" boolean,
  featured boolean,
  added    timestamp,
  modified timestamp)
 SERVER mysql_server OPTIONS (dbname 'bcteka', table_name 'collections');


CREATE FOREIGN TABLE collection_trees (
  collection_id integer,
  parent_collection_id integer,
  name text)
 SERVER mysql_server OPTIONS (dbname 'bcteka', table_name 'collection_trees');

CREATE FOREIGN TABLE element_sets (
  id integer,
  record_type varchar(50),
  name        varchar(255),
  description text)
 SERVER mysql_server OPTIONS (dbname 'bcteka', table_name 'element_sets');


CREATE FOREIGN TABLE element_texts(
 id           integer,
 record_id    integer,
 record_type  varchar(50),
 element_id   integer,
 html         boolean,
 text         text)
  SERVER mysql_server OPTIONS (dbname 'bcteka', table_name 'element_texts');

CREATE FOREIGN TABLE elements(
 id        integer,
 element_set_id integer,
 "order"   integer,
 name      varchar(255),
 description text,
 comment text)
  SERVER mysql_server OPTIONS (dbname 'bcteka', table_name 'elements');

CREATE FOREIGN TABLE files(
  id integer,
  item_id integer,
  "order" integer,
  "size"  integer,
  has_derivative_image  boolean,
  authentication        char(32),
  mime_type             varchar(255),
  type_os               varchar(255),
  filename              text,
  original_filename     text,
  modified              timestamp,
  added                 timestamp,
  stored                boolean,
  metadata              text)
   SERVER mysql_server OPTIONS (dbname 'bcteka', table_name 'files');

CREATE FOREIGN TABLE item_types(
 id integer,
 name varchar(255),
 description  text)
  SERVER mysql_server OPTIONS (dbname 'bcteka', table_name 'item_types');

CREATE FOREIGN TABLE item_types_elements(
 id integer,
 item_type_id integer,
 element_id integer,
 "order" integer)
  SERVER mysql_server OPTIONS (dbname 'bcteka', table_name 'item_types_elements');

CREATE FOREIGN TABLE items(
 id             integer,
 item_type_id   integer,
 collection_id  integer,
 featured       boolean,
 "public"       boolean,
 modified       timestamp,
 added          timestamp,
 owner_id       integer)
  SERVER mysql_server OPTIONS (dbname 'bcteka', table_name 'items');

CREATE FOREIGN TABLE search_texts(
 id integer,
 record_type  varchar(30),
 record_id    integer,
 "public" boolean,
 title  text,
 "text" text)
  SERVER mysql_server OPTIONS (dbname 'bcteka', table_name 'search_texts');

CREATE FOREIGN TABLE records_tags(
 id           integer,
 record_id    integer,
 record_type  varchar(50),
 tag_id       integer,
 "time"  timestamp)
  SERVER mysql_server OPTIONS (dbname 'bcteka', table_name 'records_tags');

CREATE FOREIGN TABLE tags(
 id integer,
 name varchar(255))
  SERVER mysql_server OPTIONS (dbname 'bcteka', table_name 'tags');
