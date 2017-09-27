set standard_conforming_strings to false;
set backslash_quote to 'safe_encoding';
set escape_string_warning to false;

begin;
drop table clavis.centrale_locations;
commit;

--    where (ci.home_library_id=2 and ci.item_status IN ('F','G','S'))

create table clavis.centrale_locations as
select item_id,collocazione from clavis.collocazioni cc
  join clavis.item ci using(item_id)
    where (ci.home_library_id=2 and ci.item_status NOT IN ('A','B','L','M'))
     OR (ci.home_library_id=2 and ci.owner_library_id=-1);

alter table clavis.centrale_locations add column piano varchar(24);
alter table clavis.centrale_locations add column primo_elemento varchar(6);

update clavis.centrale_locations set collocazione=replace(collocazione,'..','.') where collocazione like '%..%';
update clavis.centrale_locations set collocazione=replace(collocazione,' .','.') where collocazione like '% .%';

update clavis.centrale_locations set collocazione = replace(collocazione, 'PG ', 'PG.') where collocazione like 'PG %';
update clavis.centrale_locations set primo_elemento='PER.D' where collocazione ~ '^PER.D';

update clavis.centrale_locations set primo_elemento = substr(split_part(collocazione,'.',1),1,6);

alter table clavis.centrale_locations add column secondo_elemento varchar(4);
update clavis.centrale_locations set secondo_elemento = substr(split_part(collocazione,'.',2),1,4);
update clavis.centrale_locations set secondo_elemento=trim(secondo_elemento) where secondo_elemento like ' %';


update clavis.centrale_locations set primo_elemento='PER???' where primo_elemento = 'PER'
   and (secondo_elemento ~ '\\D' or secondo_elemento ~ '-');

alter table clavis.centrale_locations add column terzo_elemento varchar(12);
update clavis.centrale_locations set terzo_elemento = substr(split_part(collocazione,'.',3),1,12);

with numeri as
  (select item_id,regexp_matches(collocazione, '\\d+') as num
     from clavis.centrale_locations where collocazione ~ '^P\.G\. ?')
 update clavis.centrale_locations as y
     set primo_elemento='PG',
         secondo_elemento=num[1]::integer,
	 terzo_elemento=NULL
  from numeri where numeri.item_id=y.item_id;

create index clavis_centra_locations_item_id_idx on clavis.centrale_locations(item_id);
create index clavis_centra_locations_piano_idx on clavis.centrale_locations(piano);
create index clavis_centra_locations_primo_elemento_idx on clavis.centrale_locations(primo_elemento);


alter table clavis.centrale_locations add column scaffale integer;

update clavis.centrale_locations set scaffale=primo_elemento::integer where scaffale is null and primo_elemento ~ '^\\d+$';


-- Opuscoli 
update clavis.centrale_locations set piano='Secondo seminterrato' where secondo_elemento ~ '^L[BCDFGM]$';

-- 1-58  => ottavo
update clavis.centrale_locations set piano='8° piano' where piano isnull and scaffale between 1 and 58;

-- 60-63 => primo
update clavis.centrale_locations set piano='1° piano' where piano isnull and scaffale between 60 and 63;

-- 67-79  | Manoscritti e rari
update clavis.centrale_locations set piano='Manoscritti e rari' where piano isnull and scaffale between 67 and 79;

-- 80-206 | 3° piano
update clavis.centrale_locations set piano='3° piano' where piano isnull and scaffale between 80 and 206;

-- 207-299 | 4° piano
update clavis.centrale_locations set piano='4° piano' where piano isnull and scaffale between 207 and 299;

-- 300-392 | 5° piano
update clavis.centrale_locations set piano='5° piano' where piano isnull and scaffale between 300 and 392;

-- 393-399 | 6° piano
update clavis.centrale_locations set piano='6° piano' where piano isnull and scaffale between 393 and 399;

-- 400-402 | Manoscritti e rari
update clavis.centrale_locations set piano='Manoscritti e rari' where piano isnull and scaffale between 400 and 402;

-- 403-404 | 9° piano
update clavis.centrale_locations set piano='9° piano' where piano isnull and scaffale in(403,404);

-- 405 | Manoscritti e rari
update clavis.centrale_locations set piano='Manoscritti e rari' where piano isnull and scaffale = 405;

-- 406 | 6° piano
update clavis.centrale_locations set piano='6° piano' where piano isnull and scaffale = 406;

-- 407-408 | Manoscritti e rari
update clavis.centrale_locations set piano='Manoscritti e rari' where piano isnull and scaffale in(407,408);

-- 409 | 5° piano
update clavis.centrale_locations set piano='5° piano' where piano isnull and scaffale = 409;

-- 410-413 | Manoscritti e rari
update clavis.centrale_locations set piano='Manoscritti e rari' where piano isnull and scaffale between 410 and 413;

-- 414-510 | 6° piano
update clavis.centrale_locations set piano='6° piano' where piano isnull and scaffale between 414 and 510;

-- 601-605 | 4° piano
update clavis.centrale_locations set piano='4° piano' where piano isnull and scaffale between 601 and 605;

-- 607-640 | 4° piano
update clavis.centrale_locations set piano='4° piano' where piano isnull and scaffale between 607 and 640;

-- 664-667 | 4° piano
update clavis.centrale_locations set piano='4° piano' where piano isnull and scaffale between 664 and 667;

-- 680-703 | 6° piano
update clavis.centrale_locations set piano='6° piano' where piano isnull and scaffale between 680 and 703;

-- 705-715 | 4° piano
update clavis.centrale_locations set piano='4° piano' where piano isnull and scaffale between 705 and 715;

-- 811-820 | 9° piano
update clavis.centrale_locations set piano='9° piano' where piano isnull and scaffale between 811 and 820;

----------------------
-- Casi particolari --
----------------------

-- 403.A 404.A 405.A | 9° piano
update clavis.centrale_locations set piano = '9° piano' where scaffale between 403 and 405 and secondo_elemento='A';

-- 503.F (arabi) secondo seminterrato
update clavis.centrale_locations set piano = 'Secondo seminterrato' where scaffale = 503 and secondo_elemento='F';

-- 510.A.10-522.F.10 | -2°
-- In realtà semplifico, impostando il piano per tutti gli esemplari con scaffale dal 511 al 522
update clavis.centrale_locations set piano='Secondo seminterrato' where piano isnull and scaffale between 511 and 522;

-- Solo per 510.A (tutti i numeri di catena, però; non solo dal numero 10.. chiarire la situazione)
update clavis.centrale_locations set piano='Secondo seminterrato' where scaffale=510 and secondo_elemento='A';

-- 523-556 (foglio di Pat Carrera) nono piano
update clavis.centrale_locations set piano = '9° piano' where scaffale between 523 and 556;

-- 551.A.11-565.E.23 | -2°
update clavis.centrale_locations set piano='Secondo seminterrato' where scaffale = 551 and secondo_elemento='A';
update clavis.centrale_locations set piano='Secondo seminterrato' where scaffale between 552 and 565;

-- 566.A-573 | 9° piano
update clavis.centrale_locations set piano='9° piano' where piano isnull and scaffale = 566 and secondo_elemento='A';
update clavis.centrale_locations set piano='9° piano' where piano isnull and scaffale between 567 and 573;

-- 577.A.3 e 600.C.60 | 9° piano
-- in realtà è 577.A  e  600.C
update clavis.centrale_locations set piano='9° piano' where scaffale = 577 and secondo_elemento='A';
update clavis.centrale_locations set piano='9° piano' where scaffale = 600 and secondo_elemento='C';

-- 582.D.37-582.D.105 | 9° piano
update clavis.centrale_locations set piano='9° piano' where scaffale = 582 and secondo_elemento='D';

-- 582.E.1-582.E.73 | 9° piano
update clavis.centrale_locations set piano='9° piano' where scaffale = 582 and secondo_elemento='E';

-- 587.A.1-598.H | -2°
update clavis.centrale_locations set piano='Secondo seminterrato' where scaffale between 587 and 598;

-- 599 è tutto al 9° piano tranne la lettera H
update clavis.centrale_locations set piano='9° piano' where piano isnull and scaffale=599;
update clavis.centrale_locations set piano='Secondo seminterrato' where scaffale=599 and secondo_elemento='H';

-- 600 Ufficio informazioni
update clavis.centrale_locations set piano='Uff. informazioni' where scaffale=600;
update clavis.centrale_locations set piano='Manoscritti e rari' where scaffale=600 and collocazione ~* 'manos';


-- 602.D.1-641.F.1 | 9° piano (chiarire)

-- 606.G | -2°
update clavis.centrale_locations set piano='Secondo seminterrato' where scaffale=606 and secondo_elemento='G';
-- 601-640
update clavis.centrale_locations set piano='4° piano' where scaffale between 601 and 640 and piano is null;

-- 636.D | 9° piano
-- 640.A | 9° piano
update clavis.centrale_locations set piano='9° piano' where (scaffale=636 and secondo_elemento='D')
                                                  or (scaffale=640 and secondo_elemento='A');

-- 641.A.1-653.F.7 | -2°
update clavis.centrale_locations set piano='Secondo seminterrato' where scaffale between 641 and 653
                                  and secondo_elemento ~ '^[A-G]$';

-- 643.D.E.G   | 9° piano
-- 648.B-C.    | 9° piano
-- 650.A-G     | 9° piano
-- 652.G       | 9° piano
-- 660.B-C-D-F | 9° piano
-- 662.B       | 9° piano
update clavis.centrale_locations set piano='9° piano' where (scaffale=643 and secondo_elemento IN('D','E','G'))
                                                  or (scaffale=648 and secondo_elemento IN('B','C'))
						  or (scaffale=650 and secondo_elemento between 'A' and 'G')
						  or (scaffale=652 and secondo_elemento = 'G')
                                                  or (scaffale=660 and secondo_elemento IN('B','C','D','F'))
 						  or (scaffale=662 and secondo_elemento = 'B');

-- 660.A.1-660.A.538 | -2°
update clavis.centrale_locations set piano='Secondo seminterrato' where scaffale = 660
                                  and secondo_elemento = 'A';

-- 830.A-B-C-D-E-F | -2°
-- 830.LF-LG       | -2°  (in realtà gli LX sono già assegnati al -2 da una precedente regola)
--update clavis.centrale_locations set piano='Secondo seminterrato' where
--                           (scaffale = 830 and secondo_elemento between 'A' and 'F')
--			or (scaffale = 830 and secondo_elemento in ('LF','LG'));
-- Ma tutto 830 è a -2, quindi:
update clavis.centrale_locations set piano='Secondo seminterrato' where scaffale=830;

-- BCTXX.Z | 9° piano
update clavis.centrale_locations set piano='9° piano' where primo_elemento ~ '^BCT\.\.$' and secondo_elemento='Z';
-- BCT09 | 5° piano
update clavis.centrale_locations set piano='5° piano' where primo_elemento='BCT09';
-- BCT09.A | 2° piano
update clavis.centrale_locations set piano='2° piano' where primo_elemento='BCT09' and secondo_elemento='A';
-- BCTXX (tranne eccezioni) | 2°
update clavis.centrale_locations set piano='2° piano' where piano is null and primo_elemento ~ '^BCT\.\.$';
-- BCTXX.AO | 2°
update clavis.centrale_locations set piano='2° piano' where primo_elemento ~ '^BCT\.\.$' and secondo_elemento='AO';

-- BIBLIO | 9° piano
update clavis.centrale_locations set piano='9° piano' where primo_elemento='BIBLIO';

-- PG
update clavis.centrale_locations set piano='Sala giornali' where primo_elemento='PG'
               and secondo_elemento::integer between 1 and 222;
update clavis.centrale_locations set piano='1° piano' where primo_elemento='PG'
               and secondo_elemento::integer between 224 and 314;
update clavis.centrale_locations set piano='Primo seminterrato' where primo_elemento='PG'
               and secondo_elemento::integer between 315 and 514;
-- P.G. 379-480; P.G. 482-485; Manoscritti e rari
update clavis.centrale_locations set piano='Manoscritti e rari' where primo_elemento='PG'
               and (
	           (secondo_elemento::integer between 379 and 480)
		OR (secondo_elemento::integer between 482 and 485));

-- BCTA - deposito esterno
update clavis.centrale_locations set piano='Deposito esterno' where primo_elemento='BCTA';

-- LP libro parlato
update clavis.centrale_locations set piano='Secondo seminterrato' where primo_elemento='LP';

-- NNXX - scaffale aperto e altre sezioni
update clavis.centrale_locations set piano='Scaffale aperto 2° piano' where primo_elemento ~ '^CC\.\.';
update clavis.centrale_locations set piano='Scaffale aperto 1° piano' where primo_elemento = 'SAP';
update clavis.centrale_locations set piano='2° piano' where primo_elemento in ('CD','DVD');
update clavis.centrale_locations set piano='Sala consultazione' where primo_elemento = 'Cons';
update clavis.centrale_locations set piano='9° piano' where primo_elemento = 'Coll';

update clavis.centrale_locations set piano='7° piano' where scaffale in(661,662) and secondo_elemento='A';

update clavis.centrale_locations set piano='Secondo seminterrato' where collocazione like 'Sez.Gioberti%';
update clavis.centrale_locations set piano='Secondo seminterrato' where collocazione like 'Libr.Gioberti%';

update clavis.centrale_locations set piano='Secondo seminterrato' where primo_elemento='SERA';


-- PER
-- PER.D (Periodici in dono, al settimo piano)
update clavis.centrale_locations set piano='7° piano' where primo_elemento IN ('PER.D', 'PERD')
         OR primo_elemento = 'PER???' and secondo_elemento='D';
update clavis.centrale_locations set piano='8° piano' where primo_elemento='PER'
                and secondo_elemento!='' and secondo_elemento::integer between 1 and 1688;
update clavis.centrale_locations set piano='7° piano' where primo_elemento='PER'
                and secondo_elemento!='' and secondo_elemento::integer >= 1689;


-- PER dal 2012 in poi, al settimo piano
update clavis.centrale_locations as cl set piano='7° piano' from clavis.item ci
  where ci.item_id=cl.item_id and cl.primo_elemento = 'PER' and ci.issue_year ~  '^\\d+$' and ci.issue_year::integer > 2011;

-- Reg  --- Manoscritti e rari (notizia da Patrizia Carrera)
update clavis.centrale_locations set piano='Manoscritti e rari' where primo_elemento='Reg';

-- S.L. (sala lettura? o secondo seminterrato in casse (secondo Luca))
update clavis.centrale_locations set piano='Secondo semint. (casse?)' where primo_elemento='S' and secondo_elemento='L';

-- A.A.
update clavis.centrale_locations set piano='9° piano' where primo_elemento='A' and secondo_elemento='A';

-- GM - microfilm (per ora approssimativo)
update clavis.centrale_locations set secondo_elemento = trim(secondo_elemento) where primo_elemento='GM';
update clavis.centrale_locations set piano='Sala giornali' where primo_elemento='GM';

update clavis.centrale_locations set piano='1° piano' where primo_elemento='GM'
       and secondo_elemento ~ '^\\d+$' and secondo_elemento::integer >= 128;

-- Fer (ferrovie)
update clavis.centrale_locations set piano='Manoscritti e rari?' where primo_elemento='Fer';

-- Sci (Fondo Sci)
update clavis.centrale_locations set piano='9° piano' where primo_elemento in ('Sci', 'Tesi');

-- Tattili
update clavis.centrale_locations set piano='2° piano' where primo_elemento = 'Tattil';

-- Archivi (Bosio, Chiara, Gianelli)
update clavis.centrale_locations set piano='Manoscritti e rari' where primo_elemento = 'Archiv';

-- Residuo Manoscritti (indicazione presente in collocazione)
update clavis.centrale_locations set piano='Manoscritti e rari' where collocazione ~* 'manos' and piano isnull;



-- Misteri da chiarire
update clavis.centrale_locations set piano='Piano da definire' where scaffale in (525,534);
update clavis.centrale_locations set piano='Sala ragazzi?' where collocazione ~* '^sala ragazzi$';

update clavis.centrale_locations set piano='Sala giornali' where piano is null and collocazione ~* 'giornali';

-- CAA (Fondazione Paideia)
update clavis.centrale_locations set piano='Scaffale aperto 2° piano' where primo_elemento = 'CAA';


update clavis.centrale_locations cl set piano='Cassa deposito esterno' from container_items ci
  join containers c on(c.id=ci.container_id) join clavis.library l on(l.library_id=c.library_id)
  where ci.item_id=cl.item_id;

update clavis.centrale_locations set piano='__non assegnato__' where piano is null;

-- riepilogo per piano
select piano,count(*) from clavis.centrale_locations group by piano order by piano;
