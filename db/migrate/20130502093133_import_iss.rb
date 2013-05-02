# See storage/preesistente/seshat/tables_dump.sh

class ImportIss < ActiveRecord::Migration
  def up
    sql = %Q{
     CREATE SCHEMA iss;
     CREATE TABLE iss.articles (
       id SERIAL PRIMARY KEY,
       issue_id integer NOT NULL,
       title character varying(240) NOT NULL,
       created_at timestamp without time zone,
       updated_at timestamp without time zone,
       created_by integer,
       updated_by integer,
       "position" integer
     );
     CREATE TABLE iss.issues (
         id SERIAL PRIMARY KEY,
         journal_id integer NOT NULL,
         annata character varying(20),
         fascicolo character varying(38),
         extra_info character varying(6),
         anno integer,
         info_fascicolo character varying(32),
         bobina character varying(9),
         created_at timestamp without time zone,
         updated_at timestamp without time zone,
         created_by integer,
         updated_by integer,
         "position" integer
     );
     CREATE TABLE iss.journals (
         id SERIAL PRIMARY KEY,
         title character varying(120) NOT NULL,
         bid character varying(12),
         created_at timestamp without time zone,
         updated_at timestamp without time zone,
         created_by integer,
         updated_by integer,
         keytit character varying(120),
         pubblicato boolean DEFAULT false NOT NULL
     );
     CREATE TABLE iss.pages (
         id SERIAL PRIMARY KEY,
         article_id integer NOT NULL,
         imagepath character varying(29),
         pagenumber character varying(20),
         sequential character varying(5),
         created_at timestamp without time zone,
         updated_at timestamp without time zone,
         created_by integer,
         updated_by integer,
         "position" integer
     );
CREATE INDEX index_articles_on_title ON iss.articles USING btree (title);
CREATE INDEX index_issues_on_annata ON iss.issues USING btree (annata);
CREATE INDEX index_issues_on_anno ON iss.issues USING btree (anno);
CREATE INDEX index_issues_on_bobina ON iss.issues USING btree (bobina);
CREATE INDEX index_issues_on_extra_info ON iss.issues USING btree (extra_info);
CREATE INDEX index_issues_on_fascicolo ON iss.issues USING btree (fascicolo);
CREATE INDEX index_issues_on_info_fascicolo ON iss.issues USING btree (info_fascicolo);
CREATE INDEX index_journals_on_bid ON iss.journals USING btree (bid);
CREATE UNIQUE INDEX index_journals_on_bid_and_title ON iss.journals USING btree (bid, title);
CREATE INDEX index_journals_on_title ON iss.journals USING btree (title);
CREATE INDEX index_pages_on_article_id ON iss.pages USING btree (article_id);
ALTER TABLE ONLY iss.pages
    ADD CONSTRAINT article_id_fkey FOREIGN KEY (article_id) REFERENCES iss.articles(id) ON UPDATE CASCADE;
ALTER TABLE ONLY iss.articles
    ADD CONSTRAINT issue_id_fkey FOREIGN KEY (issue_id) REFERENCES iss.issues(id) ON UPDATE CASCADE;
ALTER TABLE ONLY iss.issues
    ADD CONSTRAINT journal_id_fkey FOREIGN KEY (journal_id) REFERENCES iss.journals(id) ON UPDATE CASCADE;

CREATE INDEX iss_pages_imagepath_idx on iss.pages(imagepath);
    }
    execute(sql)
  end

  def down
    sql = %Q{
      DROP SCHEMA iss CASCADE;
    }
    execute(sql)
  end
end
