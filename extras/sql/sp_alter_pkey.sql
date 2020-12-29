BEGIN;
-- Creo nuovo attributo orig_id destinato a contenere i valori degli id originali di senzaparola:
ALTER TABLE sp.sp_bibliographies ADD COLUMN orig_id character(64);
UPDATE sp.sp_bibliographies SET orig_id=id;
CREATE SEQUENCE sp.sp_bibliographies_id_seq MINVALUE 1 OWNED BY sp.sp_bibliographies.id;
ALTER TABLE sp.sp_bibliographies ALTER COLUMN id set default nextval('sp.sp_bibliographies_id_seq');
UPDATE sp.sp_bibliographies SET id=nextval('sp.sp_bibliographies_id_seq');

ALTER TABLE sp.sp_sections DROP CONSTRAINT sp_sections_bibliography_id_fkey;
ALTER TABLE sp.sp_items    DROP CONSTRAINT    sp_items_bibliography_id_fkey;
ALTER TABLE sp.sp_bibliographies DROP CONSTRAINT sp_bibliographies_pkey;
ALTER TABLE sp.sp_bibliographies ALTER column id TYPE integer USING id::integer;
ALTER TABLE sp.sp_sections ALTER column bibliography_id TYPE integer USING bibliography_id::integer;
ALTER TABLE sp.sp_items ALTER column bibliography_id TYPE integer USING bibliography_id::integer;
ALTER TABLE sp.sp_bibliographies ADD PRIMARY KEY (id);
ALTER TABLE sp.sp_sections
    ADD CONSTRAINT sp_sections_bibliography_id_fkey FOREIGN KEY (bibliography_id) REFERENCES sp.sp_bibliographies(id)
      ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE sp.sp_items
    ADD CONSTRAINT sp_items_bibliography_id_fkey FOREIGN KEY (bibliography_id) REFERENCES sp.sp_bibliographies(id)
      ON UPDATE CASCADE ON DELETE CASCADE;
COMMIT;


/* Qualora fosse necessario rifare un'importazione generale dei dati originali di SenzaParola
   bisogna ripristinare id a char(64)

BEGIN;
ALTER TABLE sp.sp_sections DROP CONSTRAINT sp_sections_bibliography_id_fkey;
ALTER TABLE sp.sp_items DROP CONSTRAINT sp_items_bibliography_id_fkey;
ALTER TABLE sp.sp_bibliographies ALTER column id TYPE char(64);
ALTER TABLE sp.sp_sections ALTER column bibliography_id TYPE char(64);
ALTER TABLE sp.sp_items ALTER column bibliography_id TYPE char(64);
ALTER TABLE sp.sp_bibliographies ALTER COLUMN id DROP DEFAULT;
DROP SEQUENCE sp.sp_bibliographies_id_seq;

ALTER TABLE sp.sp_sections
    ADD CONSTRAINT sp_sections_bibliography_id_fkey FOREIGN KEY (bibliography_id) REFERENCES sp.sp_bibliographies(id)
      ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE sp.sp_items
    ADD CONSTRAINT sp_items_bibliography_id_fkey FOREIGN KEY (bibliography_id) REFERENCES sp.sp_bibliographies(id)
      ON UPDATE CASCADE ON DELETE CASCADE;

UPDATE sp.sp_bibliographies SET id=orig_id;
ALTER TABLE sp.sp_bibliographies DROP COLUMN orig_id;
COMMIT;

*/
