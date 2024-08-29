# coding: utf-8
# -*- mode: ruby;-*-

desc 'Importazione fatture Leggere (provvisorio)'


task :cr_invoices_import => :environment do
  puts "disabilitato"
  exit
  sql=%Q{
     set search_path to sbct_acquisti;
     DROP TABLE IF EXISTS invoice_items;
     DROP TABLE IF EXISTS invoices;

     CREATE TABLE invoices
     (
     invoice_id serial primary key,
     label varchar(128),
     clavis_invoice_id integer,
     total_amount numeric(10,2),
     notes text
     );

     CREATE TABLE invoice_items
     (
     invoice_id integer not null references invoices on update cascade on delete cascade,
     cliente varchar(128),
     tipo_documento varchar(24),
     ddt_numero integer,
     ddt_date date,
     ean char(13),
     titolo text,
     autore text,
     editore text,
     quantita integer,
     valore_unitario numeric(10,2),
     aliquota integer,
     sconto numeric(10,2),
     netto numeric(10,4),
     data_prenotazione timestamp,
     prog_ordine char(2),
     rif_ordine char(24)
     );
  }

  SbctList.connection.execute(sql)

  sourcedir='/home/ror/clavisbct/leggere/F*.csv'
  config   = Rails.configuration.database_configuration
  dbname=config[Rails.env]["database"]
  username=config[Rails.env]["username"]
  tmp_sql_file = "/tmp/importa_fatture.sql"
  
  # Assumo in formato nome file come questo: "/home/ror/clavisbct/leggere/Fattura_2022_5620.csv"
  # Devo estrarre "5620"
  Dir.glob(sourcedir).each do |f|
    numero_fattura = f.split('_').last.split('.').first
    sbct_invoice = SbctInvoice.create(label:"#{numero_fattura} del 2022")
    fd = File.open(tmp_sql_file, 'w')
    fd.write(%Q{set search_path to sbct_acquisti;\n})
    fd.write(%Q{COPY invoice_items(invoice_id,cliente,tipo_documento,ddt_numero,ddt_date,ean,titolo,autore,editore,quantita,valore_unitario,aliquota,sconto,netto,data_prenotazione,prog_ordine,rif_ordine) FROM stdin;\n})
    CSV.foreach(f) do |row|
      # Sostituisco la prima colonna con invoice_id:
      row[0]=sbct_invoice.id
      fd.write(%Q{#{row.join("\t")}\n})
    end
    fd.write("\\.\n")
    fd.close
    cmd="/usr/bin/psql --no-psqlrc -d #{dbname} #{username}  -f #{tmp_sql_file}"
    puts "executing #{cmd}..."
    Kernel.system(cmd)
  end
end

           
