# coding: utf-8
# -*- mode: ruby;-*-

desc 'Importazione tabella ACQUISTI dal DB Centro Rete'


task :cr_acquisti_import => :environment do
  puts "disabilitato"
  exit
  # fd=STDOUT
  sql_file = "/tmp/importa_centrorete.sql"
  fd = File.open(sql_file, 'w')

  fd.write("DROP SCHEMA sbct_acquisti CASCADE;\n")
  fd.write("CREATE SCHEMA sbct_acquisti;\n")
  # fd.write("CREATE TABLE sbct_acquisti.liste (id_lista serial primary key, data_libri date not null, wrk boolean, wrk_ut boolean);\n");
  # fd.write("CREATE TABLE sbct_acquisti.liste (id_lista serial primary key, data_libri date not null, wrk boolean);\n");
  fd.write("CREATE TABLE sbct_acquisti.liste (id_lista serial primary key, data_libri date, id_tipo_titolo char(1));\n");
  fd.write("CREATE TABLE sbct_acquisti.l_titoli_liste (id_titolo integer not null, id_lista integer not null);\n");
  fd.write("CREATE TABLE sbct_acquisti.l_budgets_libraries (budget_id integer not null, clavis_library_id integer not null, quota numeric(10,2));\n");
  fd.write("create unique index budget_id_clavis_library_id_ndx on sbct_acquisti.l_budgets_libraries(budget_id,clavis_library_id);\n");
  fd.write(%Q{CREATE TABLE sbct_acquisti.titoli AS SELECT id as id_titolo, ean::varchar(32), isbn, editore, autore,
             titolo, collana, data_libri, tipo_riga::char(1) as id_tipo_titolo, replace(prezzo, ',', '.') as prezzo, utente, 
             case when  wrk='1' then true::boolean else false::boolean end as wrk,
             case when  def='1' then true::boolean else false::boolean end as def
              FROM cr_acquisti.acquisti;\n})
  fd.write(%Q{CREATE TABLE sbct_acquisti.budgets (budget_id serial primary key, label varchar(128), clavis_budget_id integer, total_amount numeric(10,2), locked boolean default false);
              INSERT INTO sbct_acquisti.budgets(budget_id,label,locked) values(0,'Pregresso (sistema CR)',true);})
  fd.write(%Q{CREATE TABLE sbct_acquisti.copie (id_copia serial primary key, id_titolo integer, data_libri date,
                  budget_id integer references sbct_acquisti.budgets(budget_id) on update cascade on delete set null,
           note_fornitore text,note_interne text,library_id integer, id_causale integer, numcopie integer, date_created timestamp default now());\n})
  h=ClavisLibrary.siglebct
  h.delete(:arcsto)
  fd.write(%Q{COPY sbct_acquisti.copie(id_titolo,data_libri,library_id,numcopie,id_causale,date_created) FROM stdin;\n})
  h.each_pair do |f,library_id|
    sql=%Q{select id as id_titolo,data_libri,
                 #{f} as numcopie,
                 case when causale_richiesta is null then '\\N' else causale_richiesta end
                 FROM cr_acquisti.acquisti where #{f}::integer > 0;}
    ActiveRecord::Base.connection.execute(sql).to_a.each do |r|
      data_libri=r['data_libri'].nil? ? '\\N' : r['data_libri'] 
      fd.write("#{r['id_titolo']}\t#{data_libri}\t#{library_id}\t#{r['numcopie']}\t#{r['causale_richiesta']}\t\\N\n")
    end
  end
  fd.write("\\.\n")

  # Seconda parte: alterazione tabelle, constraints, indici etc

  fd.write("INSERT INTO sbct_acquisti.liste (data_libri,id_tipo_titolo)
               (select distinct data_libri,tipo_riga from cr_acquisti.acquisti where data_libri is not null group by data_libri,tipo_riga);\n")
  
  fd.write(%Q{
     set search_path to sbct_acquisti;

create table sbct_acquisti.library_codes
  (clavis_library_id integer not null,
   label varchar(6) not null,
   primary key(label,clavis_library_id));
COPY sbct_acquisti.library_codes(label, clavis_library_id) FROM stdin;
A	10
ARCSTO	31
B	11
BEL	4
CI	28
D	13
E	14
F	15
G	496
H	16
I	17
L	18
M	19
MAN	7
MAR	8
MUS	3
N	20
O	21
P	22
Q	2
R	23
S	24
STR	9
T	25
U	26
V	27
Y	1121
Z	29
\\.\n


     insert into l_titoli_liste(id_titolo,id_lista)
       (select t.id_titolo,l.id_lista from titoli t join liste l using(data_libri,id_tipo_titolo));
     alter table titoli drop column data_libri;
     alter table liste add column label varchar(64);


     create sequence titoli_id_titolo_seq;
     alter table titoli alter column id_titolo set default nextval('titoli_id_titolo_seq');
     alter table titoli alter column id_titolo set not null;
     alter sequence titoli_id_titolo_seq owned by titoli.id_titolo;
     alter table titoli add primary key(id_titolo);
     select setval('titoli_id_titolo_seq', (select max(id_titolo) FROM titoli)+1);


     alter table titoli add column created_by integer references public.users on update cascade on delete set null;
     alter table titoli add column updated_by integer references public.users on update cascade on delete set null;
     alter table titoli add column date_created timestamp;
     alter table titoli add column date_updated timestamp;
     alter table titoli alter column date_created set default now();
     alter table titoli alter column date_updated set default now();
     alter table titoli add column datapubblicazione date;
     alter table titoli add column reparto text;
     alter table titoli add column sottoreparto text;
     alter table titoli add column target_lettura text;
     alter table titoli add column anno integer;
     alter table titoli add column fornitore char(128);
     alter table titoli add column id_ordine char(64);
     alter table titoli add column note text;

     alter table l_titoli_liste add constraint id_titolo_fkey foreign key(id_titolo) references titoli
        on update cascade on delete cascade;
     alter table l_titoli_liste add constraint id_lista_fkey foreign key(id_lista) references liste
        on update cascade on delete cascade;
     alter table l_titoli_liste add primary key(id_titolo,id_lista);
     alter table titoli add column manifestation_id integer;

     CREATE TABLE causali_richiesta as (select id as id_causale,causale from cr_acquisti.causale_richiesta);
     alter table causali_richiesta add primary key(id_causale);
     alter table causali_richiesta alter COLUMN causale type varchar(64);

     CREATE TABLE tipi_titolo as (select tipo_riga::char(1) as id_tipo_titolo,descrizione_riga as tipo_titolo from cr_acquisti.tipo_riga);
     alter table tipi_titolo add primary key(id_tipo_titolo);
     alter table tipi_titolo alter COLUMN tipo_titolo type varchar(64);


     alter table liste add column budget_label varchar(255);
     alter table liste add column created_by integer references public.users on update cascade on delete set null;
     alter table liste add column updated_by integer references public.users on update cascade on delete set null;
     alter table liste add column date_created timestamp;
     alter table liste add column date_updated timestamp;
     alter table liste alter column date_created set default now();
     alter table titoli alter column date_updated set default now();



     alter table liste add constraint id_tipo_titolo_fkey foreign key(id_tipo_titolo) references tipi_titolo
        on update cascade on delete set null;

     update titoli set prezzo = replace(prezzo, ' ', '') where prezzo !~ '^([0-9]+[.]?[0-9]*|[.][0-9]+)$';
     update titoli set prezzo = NULL where prezzo !~ '^([0-9]+[.]?[0-9]*|[.][0-9]+)$'; 
     alter table titoli alter COLUMN prezzo type numeric(10,2) using prezzo::numeric(10,2);

     CREATE TABLE order_status(id char(1) PRIMARY KEY, label varchar(64));
     insert into order_status(id,label) values('A', 'Arrivato');
     insert into order_status(id,label) values('N', 'Non disponibile presso il fornitore');
     insert into order_status(id,label) values('O', 'Ordinato');
     insert into order_status(id,label) values('S', 'Selezionato');
     insert into order_status(id,label) values('X', 'Annullato');


     -- alter table copie add column id_lista integer;
     alter table copie add column id_ordine varchar(64);
     -- update copie c set id_lista = l.id_lista from liste l where c.id_lista is null and l.data_libri=c.data_libri;
     -- update copie set token=split_part(invio,'_',1)::char(2) where invio notnull and token is null;
     alter table copie drop column data_libri;
     -- alter table copie add constraint id_lista_fkey foreign key(id_lista) references liste on update cascade on delete set null;
     alter table copie add constraint id_causale_fkey foreign key(id_causale) references causali_richiesta
        on update cascade on delete set null;
     alter table copie add constraint id_titolo_fkey foreign key(id_titolo) references titoli
        on update cascade on delete cascade;
     alter table copie add column created_by integer references public.users on update cascade on delete set null;
     alter table copie add column updated_by integer references public.users on update cascade on delete set null;
     alter table copie add column date_updated timestamp;
     alter table copie alter column date_updated set default now();

     alter table copie add column order_status char(1) references order_status on update cascade on delete set null;



     -- delete from copie where id_lista isnull ;
     -- alter table copie alter COLUMN id_lista set not null;
     alter table copie alter COLUMN numcopie set default 1;
     alter table copie alter COLUMN id_titolo set not null;
     alter table copie alter COLUMN library_id set not null;
     create unique index copie_id_titolo_library_id_budget_id on sbct_acquisti.copie(id_titolo,library_id,budget_id,id_ordine);


     /*
     update l_titoli_liste set id_lista = (select id_lista from liste where data_libri='2026-01-01' and id_tipo_titolo='N')
            where id_lista in (select id_lista from liste where data_libri between '2026-01-02' and '2026-02-03');
     update liste set label = 'Acquisti MiC 2022' where data_libri='2026-01-01' and id_tipo_titolo='N';
     */

     update liste set label = 'MiC - 1 Ragazzi 0-2 anni' where data_libri='2022-06-10' and id_tipo_titolo='R';
     update liste set label = 'MiC - 2 Ragazzi 3-5 anni' where data_libri='2022-06-11' and id_tipo_titolo='R';
     update liste set label = 'MiC - 3 Ragazzi 6-10 anni' where data_libri='2022-06-18' and id_tipo_titolo='R';
     update liste set label = 'MiC - 4 Ragazzi 10-15 anni' where data_libri='2022-06-25' and id_tipo_titolo='R';   
     update liste set label = 'MiC - 5 Ragazzi fumetti' where data_libri='2022-06-28' and id_tipo_titolo='R';
     update liste set label = 'MiC - 6 Ragazzi (in lingua straniera)' where data_libri='2022-07-02' and id_tipo_titolo='R';     
     update liste set label = 'MiC - 7 Young adults' where data_libri='2022-06-27' and id_tipo_titolo='R';
     update liste set label = 'MiC - 8 Ragazzi saggistica' where data_libri='2022-06-04' and id_tipo_titolo='R';

     insert into liste (label,budget_label) values ('Acquisti MiC 2022','MiC 2022');
     
     -- insert into liste (data_libri,label,id_tipo_titolo) values (now(),'MiC - Ragazzi (tutti)','R');
 
     alter table titoli drop column id_tipo_titolo ;

     CREATE INDEX sbct_title_idx ON sbct_acquisti.titoli USING gin(to_tsvector('simple', titolo));
     CREATE INDEX sbct_autore_idx ON sbct_acquisti.titoli USING gin(to_tsvector('simple', autore));

     delete from l_titoli_liste where id_titolo in
       (select t.id_titolo from liste l join l_titoli_liste tl using(id_lista) join titoli t using(id_titolo)
       where l.label notnull and t.def);

     insert into sbct_acquisti.budgets (clavis_budget_id, label, total_amount)
      (select b.budget_id,b.budget_title || ' ' || l.shortlabel, b.total_amount
        from clavis.budget b join clavis.library l using(library_id) where library_id=1 or budget_title='MiC 2022');

     insert into l_budgets_libraries (budget_id , clavis_library_id)
       (select b.budget_id,library_id from budgets b join clavis.budget cb on(cb.budget_id = b.clavis_budget_id));

     update sbct_acquisti.titoli set isbn = NULL where isbn = '0';
  create table orders (ean char(13), data timestamp, valore_unitario numeric(10,2), note varchar(129), supplier_id integer NOT NULL, row_number integer NOT NULL);

     #{SbctTitle.sql_for_update_manifestation_ids}

     CREATE TABLE suppliers
     (
     supplier_id integer primary key,
     supplier_name varchar(255)
     );


-- Leggere:
     INSERT into suppliers(supplier_id,supplier_name) (select supplier_id,supplier_name from clavis.supplier where supplier_id = 384);
-- Libreria dei ragazzi:
     INSERT into suppliers(supplier_id,supplier_name) (select supplier_id,supplier_name from clavis.supplier where supplier_id = 154);
-- Donatore generico:
     INSERT into suppliers (supplier_id, supplier_name) values (20, 'Donatore non meglio specificato (generico)');
-- Altri fornitori a caso (per avere qualche dato su cui lavorare):
     -- INSERT into suppliers(supplier_id,supplier_name) (select supplier_id,supplier_name from clavis.supplier where supplier_name ~* '^librer') ON CONFLICT (supplier_id) DO NOTHING;
     insert into suppliers(supplier_id,supplier_name) (select supplier_id,supplier_name from clavis.supplier where supplier_name ~ '^MiC22 - ');






     ALTER TABLE budgets add column supplier_id integer references suppliers on update cascade on delete set null;
     UPDATE budgets SET supplier_id = 384 WHERE clavis_budget_id=63;
     UPDATE budgets SET supplier_id = 154 WHERE clavis_budget_id=57;
     UPDATE budgets SET supplier_id = 154 WHERE clavis_budget_id=85;


     ALTER TABLE copie add column supplier_id integer references suppliers on update cascade on delete set null;
     ALTER TABLE copie add column prezzo numeric(10,2);
     ALTER TABLE copie add column order_date date;

    update titoli set ean = isbn where isbn notnull and ean is null;

    alter table liste add column parent_id integer references liste on update cascade on delete set null;
    update liste as t set parent_id=l.id_lista from liste l where l.id_lista = 5044 and t.label notnull and t.id_lista!=l.id_lista;

    CREATE TABLE sbct_acquisti.import_titoli (id_lista integer not null references sbct_acquisti.liste on update cascade on delete cascade,
           id_titolo integer, ean varchar(32), autore text, titolo text,
           editore text, collana text, prezzo numeric(10,2), siglebib text,
           datapubblicazione date,
           reparto text, sottoreparto text,
           fornitore varchar(128),
           id_ordine varchar(64),
           target_lettura varchar(128),
           anno integer,
           note text,
           date_created timestamp, created_by integer,
           original_filename varchar(128));

    CREATE TABLE sbct_acquisti.import_copie (
           id_copia integer,
           id_titolo integer not null references sbct_acquisti.titoli on update cascade on delete cascade,
           budget_id integer references sbct_acquisti.budgets on update cascade on delete set null,
           library_id integer not null,
           id_ordine varchar(64),
           supplier_id integer references sbct_acquisti.suppliers on update cascade on delete set null);
    CREATE UNIQUE INDEX import_copie_id_copia_idx ON sbct_acquisti.import_copie(id_copia);


     #{SbctItem.sql_for_set_clavis_supplier}

/*
update sbct_acquisti.copie c
   set budget_id=(select budget_id from sbct_acquisti.budgets where clavis_budget_id=63),
     prezzo = t.prezzo - (cs.discount*t.prezzo)/100, order_status='A'
      from sbct_acquisti.titoli t join clavis.item ci using(manifestation_id)
         join clavis.supplier cs using(supplier_id)
            where
	    c.budget_id is null and ci.supplier_id = 384 and c.id_titolo=t.id_titolo and date_part('year',ci.inventory_date)='2022';


update sbct_acquisti.copie c
   set budget_id=(select budget_id from sbct_acquisti.budgets where clavis_budget_id=57),
     prezzo = t.prezzo - (cs.discount*t.prezzo)/100, order_status='A'
      from sbct_acquisti.titoli t join clavis.item ci using(manifestation_id)
         join clavis.supplier cs using(supplier_id)
            where
	    c.budget_id is null and ci.supplier_id = 154 and c.id_titolo=t.id_titolo and date_part('year',ci.inventory_date)='2022';
*/

update sbct_acquisti.copie c set supplier_id = 20
   from sbct_acquisti.l_titoli_liste tl join sbct_acquisti.liste l using(id_lista)
   where c.supplier_id is null and c.id_titolo=tl.id_titolo and l.id_lista=tl.id_lista and l.id_tipo_titolo = 'D';

update sbct_acquisti.titoli t set reparto = 'RAGAZZI' from sbct_acquisti.l_titoli_liste tl join sbct_acquisti.liste l using(id_lista) where t.id_titolo=tl.id_titolo and t.reparto is null AND l.id_tipo_titolo='R';


update sbct_acquisti.titoli set reparto = 'FUMETTI' where reparto is null and  editore ~* 'Sergio Bonelli Editore';


    set search_path to public;
  })

  # puts "test:\nselect t.id_titolo,t.titolo,l.* from titoli t join l_titoli_liste tl using(id_titolo) join liste l using(id_lista) where l.id_lista = 2100;"

  fd.close

  config   = Rails.configuration.database_configuration
  dbname=config[Rails.env]["database"]
  username=config[Rails.env]["username"]
  cmd="/usr/bin/psql --no-psqlrc -d #{dbname} #{username}  -f #{sql_file}"
  puts "executing #{cmd}..."
  Kernel.system(cmd)

  puts "Importo titoli nella lista generale MiC 2022"
  sbctlist = SbctList.find_by_label('Acquisti MiC 2022')
  sbctlist.importa_da_liste(SbctList.where("id_tipo_titolo = 'P' AND data_libri between '2026-01-02' and '2026-02-10'"))
  sbctlist.importa_da_liste(SbctList.where('label is not null'))
  sbctlist.budgets_assign

  # SbctList.find_by_label('MiC - Ragazzi (tutti)').importa_da_liste(SbctList.where("label ~ '^MiC'"))


  user=User.find(9)
  l=SbctList.create(label:"Vetrine Leggere da giugno 2022", budget_label:"Acquisto libri adulti - Leggere")
  puts "Lista d'acquisto #{l.label}"
  l.load_data_from_excel("/home/seb/uploaded/2022_24_12-18_giugno.xlsx",user)
  l.load_data_from_excel("/home/seb/uploaded/2022_25_19-25_giugno.xlsx",user)
  l.load_data_from_excel("/home/seb/uploaded/2022_26_26_giugno-2_luglio.xlsx",user)
  l.load_data_from_excel("/home/seb/uploaded/2022_27_3-9_luglio.xlsx",user)
  l.load_data_from_excel("/home/seb/uploaded/2022_28_10-16_luglio.xlsx",user)
  l.load_data_from_excel("/home/seb/uploaded/2022_29_17-23_luglio.xlsx",user)
  l.load_data_from_excel("/home/seb/uploaded/2022_30_24-30_luglio.xlsx",user)
  l.load_data_from_excel("/home/seb/uploaded/2022_31_31_luglio-6_agosto.xlsx",user)
  l.load_data_from_excel("/home/seb/uploaded/2022_34_21-27_agosto.xlsx",user)
  l.load_data_from_excel("/home/seb/uploaded/2022_35_28_agosto-3_settembre.xlsx",user)

# <<-COMMENT

  l=SbctList.create(label:"Libri per ragazzi", budget_label:"Libri per ragazzi")
  puts "Lista d'acquisto #{l.label}"
  l.load_data_from_excel("/home/seb/uploaded/Acquisti ragazzi 2021-2022.xlsx",user)

  l=SbctList.create(label:"Musicale MiC 2022", budget_label:"MiC 2022")
  puts "Lista d'acquisto #{l.label}"
  l.load_data_from_excel("/home/seb/uploaded/Musicale_AcquistiMIC22.xlsx",user)

  l=SbctList.create(label:"Studi locali MiC", budget_label:"MiC 2022")
  puts "Lista d'acquisto #{l.label}"
  l.load_data_from_excel("/home/seb/uploaded/proposte acquisto 2022_studi locali.xls",user)

  # File con problemi, non lo devo caricare
  #l=SbctList.create(label:"Integrazioni Centrale MiC2022", budget_label:"MiC 2022")
  #puts "Lista d'acquisto #{l.label}"
  #l.load_data_from_excel("/home/seb/uploaded/integrazionicentrale.xlsx",user)

  l=SbctList.create(label:"Archivio Storico MiC 2022", budget_label:"MiC 2022")
  puts "Lista d'acquisto #{l.label}"
  l.load_data_from_excel("/home/seb/uploaded/ArchivioStoricoMiC2022.xlsx",user)


  l=SbctList.create(label:"Nati per leggere 2022", budget_label:"Finanziamento San Paolo NPL")
  puts "Lista d'acquisto #{l.label}"
  l.load_data_from_excel("/home/seb/uploaded/Elenco titoli per progetto Nati per leggere.xlsx",user)



  
# COMMENT


  cmd=%Q{/usr/bin/psql clavisbct_development informhop -c "\\COPY sbct_acquisti.orders from /home/seb/Ordini_20220712_165403.csv CSV HEADER"}
  puts "executing #{cmd}..."
  Kernel.system(cmd)


  ActiveRecord::Base.connection.execute("update sbct_acquisti.copie set order_status = 'S' where order_status is null and budget_id is not null")
  ActiveRecord::Base.connection.execute("update sbct_acquisti.suppliers set supplier_name = concat('MiC22 - ', supplier_name) where supplier_name ~ '^Libr' and supplier_id!=154")

  SbctBudget.allinea_prezzi_copie


  # Fornitori per Ragazzi segnalati da Daniela L.
  # 470 MiC22 - Diorama di Pompa Filomena
  # 471 MiC22 - Maggiora Mara Francesca
  # 481 MiC22 - AXOLOTL – SOCIETA’ COOPERATIVA
  # 486 MiC22 - La barchetta di Carta di Nadia Buona
  # 490 MiC22 - Libreria dei ragazzi di Parola Anna Maria & C s.n.c.
  #SbctBudget.assegna_fornitori('desc',[],[470,471,481,486,490],"t.reparto='RAGAZZI'")
  #SbctBudget.loop_assegna_fornitori('asc',[],[470,471,481,486,490],"t.reparto='RAGAZZI'")

  #SbctBudget.assegna_fornitori('desc')
  # Riempimento:
  #SbctBudget.loop_assegna_fornitori('asc')

  puts "last step: creating fulltext index..."
  SbctTitle.create_fulltext_index

end
