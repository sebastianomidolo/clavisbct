drop table schema_collocazioni_centrale;
create table schema_collocazioni_centrale (id serial primary key, piano varchar(24), scaffale varchar(24), palchetto varchar(24), filtro_colloc varchar(36));

INSERT into schema_collocazioni_centrale (piano,scaffale,palchetto) values ('9° piano', '403-405', 'A');
INSERT into schema_collocazioni_centrale (piano,scaffale,palchetto) values ('Secondo seminterrato', '503', 'F');
INSERT into schema_collocazioni_centrale (piano,scaffale,palchetto) values ('Secondo seminterrato', '510', 'A');
INSERT into schema_collocazioni_centrale (piano,scaffale,palchetto) values ('Secondo seminterrato', '551', 'A');
INSERT into schema_collocazioni_centrale (piano,scaffale,palchetto) values ('9° piano', '566', 'A');
INSERT into schema_collocazioni_centrale (piano,scaffale,palchetto) values ('9° piano', '577', 'A');
INSERT into schema_collocazioni_centrale (piano,scaffale,palchetto) values ('9° piano', '582', 'D');
INSERT into schema_collocazioni_centrale (piano,scaffale,palchetto) values ('9° piano', '582', 'E');
INSERT into schema_collocazioni_centrale (piano,scaffale,palchetto) values ('Secondo seminterrato', '599', 'H');
INSERT into schema_collocazioni_centrale (piano,scaffale,palchetto) values ('9° piano', '600', 'C');
INSERT into schema_collocazioni_centrale (piano,scaffale,filtro_colloc) values ('Manoscritti e rari', '600', '~* \'manos\'');
INSERT into schema_collocazioni_centrale (piano,scaffale,palchetto) values ('Secondo seminterrato', '606', 'G');
INSERT into schema_collocazioni_centrale (piano,scaffale,palchetto) values ('9° piano', '636', 'D');
INSERT into schema_collocazioni_centrale (piano,scaffale,palchetto) values ('9° piano', '640', 'A');
INSERT into schema_collocazioni_centrale (piano,scaffale,palchetto) values ('Secondo seminterrato', '641-653', '~ \'^[A-G]$\'');
INSERT into schema_collocazioni_centrale (piano,scaffale,palchetto) values ('9° piano', '643', 'IN(\'D\',\'E\',\'G\')');
INSERT into schema_collocazioni_centrale (piano,scaffale,palchetto) values ('9° piano', '648', 'IN(\'B\',\'C\')');
INSERT into schema_collocazioni_centrale (piano,scaffale,palchetto) values ('9° piano', '650', '~ \'^[A-G]$\'');
INSERT into schema_collocazioni_centrale (piano,scaffale,palchetto) values ('9° piano', '652', 'G');
INSERT into schema_collocazioni_centrale (piano,scaffale,palchetto) values ('Secondo seminterrato', '660', 'A');
INSERT into schema_collocazioni_centrale (piano,scaffale,palchetto) values ('9° piano', '660', 'IN(\'B\',\'C\',\'D\',\'F\')');
INSERT into schema_collocazioni_centrale (piano,scaffale,palchetto) values ('9° piano', '662', 'B');

--
INSERT into schema_collocazioni_centrale (piano,palchetto,filtro_colloc) values ('9° piano', 'Z', '~ \'^BCT..\\.\'');
INSERT into schema_collocazioni_centrale (piano,palchetto,filtro_colloc) values ('2° piano', 'A', '~ \'^BCT09\\.\'');
INSERT into schema_collocazioni_centrale (piano,palchetto,filtro_colloc) values ('2° piano', 'AO', '~ \'^BCT..\\.\'');
INSERT into schema_collocazioni_centrale (piano,filtro_colloc) values ('5° piano', '~ \'^BCT09\\.\'');
INSERT into schema_collocazioni_centrale (piano,filtro_colloc) values ('2° piano', '~ \'^BCT..\\.\'');

INSERT into schema_collocazioni_centrale (piano,filtro_colloc) values ('9° piano', '~ \'^BIBLIO\\.\'');

INSERT into schema_collocazioni_centrale (piano,filtro_colloc) values ('Scaffale aperto 1° piano', '~ \'^SAP\\.\'');


INSERT into schema_collocazioni_centrale (piano,scaffale) values ('8° piano', '1-58');
INSERT into schema_collocazioni_centrale (piano,scaffale) values ('1° piano', '60-63');
INSERT into schema_collocazioni_centrale (piano,scaffale) values ('Manoscritti e rari', '67-79');
INSERT into schema_collocazioni_centrale (piano,scaffale) values ('3° piano', '80-206');
INSERT into schema_collocazioni_centrale (piano,scaffale) values ('4° piano', '207-299');
INSERT into schema_collocazioni_centrale (piano,scaffale) values ('5° piano', '300-392');
INSERT into schema_collocazioni_centrale (piano,scaffale) values ('6° piano', '393-399');
INSERT into schema_collocazioni_centrale (piano,scaffale) values ('Manoscritti e rari', '400-402');
INSERT into schema_collocazioni_centrale (piano,scaffale) values ('9° piano', '403-404');
INSERT into schema_collocazioni_centrale (piano,scaffale) values ('Manoscritti e rari', '405-405');
INSERT into schema_collocazioni_centrale (piano,scaffale) values ('6° piano', '406-406');
INSERT into schema_collocazioni_centrale (piano,scaffale) values ('Manoscritti e rari', '407-408');
INSERT into schema_collocazioni_centrale (piano,scaffale) values ('5° piano', '409-409');
INSERT into schema_collocazioni_centrale (piano,scaffale) values ('Manoscritti e rari', '410-413');
INSERT into schema_collocazioni_centrale (piano,scaffale) values ('6° piano', '414-510');
INSERT into schema_collocazioni_centrale (piano,scaffale) values ('Secondo seminterrato', '511-522');
INSERT into schema_collocazioni_centrale (piano,scaffale) values ('9° piano', '523-556');
INSERT into schema_collocazioni_centrale (piano,scaffale) values ('Secondo seminterrato', '552-565');
INSERT into schema_collocazioni_centrale (piano,scaffale) values ('9° piano', '567-573');
INSERT into schema_collocazioni_centrale (piano,scaffale) values ('Secondo seminterrato', '587-598');
INSERT into schema_collocazioni_centrale (piano,scaffale) values ('9° piano', '599');
INSERT into schema_collocazioni_centrale (piano,scaffale) values ('Uff. informazioni', '600');
-- INSERT into schema_collocazioni_centrale (piano,scaffale) values ('4° piano', '601-640');
INSERT into schema_collocazioni_centrale (piano,scaffale) values ('4° piano', '601-605');
INSERT into schema_collocazioni_centrale (piano,scaffale) values ('4° piano', '607-640');
INSERT into schema_collocazioni_centrale (piano,scaffale) values ('4° piano', '664-667');
INSERT into schema_collocazioni_centrale (piano,scaffale) values ('6° piano', '680-703');
INSERT into schema_collocazioni_centrale (piano,scaffale) values ('6° piano', '705-715');
INSERT into schema_collocazioni_centrale (piano,scaffale) values ('9° piano', '811-820');
INSERT into schema_collocazioni_centrale (piano,scaffale) values ('Secondo seminterrato', '830');

INSERT into schema_collocazioni_centrale (piano,palchetto) values ('Secondo seminterrato', '~ \'^L[BCDFGM]$\'');

-- select * from schema_collocazioni_centrale where scaffale notnull order by split_part(scaffale,'-',1)::integer;

-- select * from schema_collocazioni_centrale order by piano;
