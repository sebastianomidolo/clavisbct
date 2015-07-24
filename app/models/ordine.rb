class Ordine < ActiveRecord::Base
  self.table_name='serials_admin_table'
  attr_accessible :titolo, :library_id, :ordanno, :numero_fattura, :issue_status, :anno_fornitura

  attr_accessor :issue_status

  belongs_to :clavis_library, :foreign_key=>:library_id
  belongs_to :clavis_manifestation, :foreign_key=>:manifestation_id

  def Ordine.fatture(library,anno_emissione=nil)
    cond=[]
    cond << "numero_fattura is not null and fattura_o_nota_di_credito = 'F'"
    cond << "library_id=#{library.id}" if !library.nil?
    cond << "date_part('year',data_emissione)=#{anno_emissione}" if !anno_emissione.nil?
    sql=%Q{select library_id,numero_fattura,data_emissione,data_pagamento,
  sum(prezzo::float) as totale_fattura,count(*) as numero_titoli
  from serials_admin_table
  where #{cond.join(' AND ')}
  group by library_id,numero_fattura,data_emissione,data_pagamento
  order by library_id,data_emissione desc,numero_fattura desc}
    puts sql
    Ordine.connection.execute(sql).to_a
  end

  # Automatizzare poi la creazione del file archivio_periodici.txt:
  # iconv -f latin1 -t utf8 /home/seb/BCT/wca22014/ProgettiCivica/Periodici/archivio_periodici.txt > /home/storage/preesistente/archivio_periodici.txt

  def Ordine.archivio_periodici_sourcefile
    '/home/storage/preesistente/archivio_periodici.txt'
  end

  def Ordine.importa_archivio_periodici
    fname=self.archivio_periodici_sourcefile

    tf = Tempfile.new("import", File.join(Rails.root.to_s, 'tmp'))

    siglebib={
      'A' => 10,
      'B' => 11,
      'C' => 8,
      'D' => 13,
      'E' => 14,
      'F' => 15,
      'G' => 27,
      'H' => 16,
      'I' => 17,
      'L' => 18,
      'M' => 19,
      'N' => 20,
      'O' => 21,
      'P' => 24,
      'Q' => 2,
      'U' => 25,
      'V' => 496,
      'W' => 3,
      'Y' => 22,
      'Z' => 29,
    }

    data=File.read(fname)
    cnt=0
    bidcnt=0
    sql=%Q{BEGIN; DROP TABLE public.archivio_periodici; COMMIT;
       CREATE TABLE public.archivio_periodici
       (title text, bid char(10), manifestation_id integer,
       library_id integer, provider varchar(12));
       COPY archivio_periodici(title,bid,manifestation_id,library_id,provider) FROM STDIN;\n}
    fdout=File.open(tf.path,'w')
    fdout.write(sql)

    data.split('TI_ ').each do |r|
      next if r.blank?
      rec="TI_ #{r}"
      record={:title=>nil, :bid=>nil, :manifestation_id=>nil, :libraries=>[]}
      rec.each_line do |l|
        a=l.split(' ')
        tag=a.shift
        content=a.join(' ').strip
        case tag
        when 'B:'
          sigla,fornitore,numcopie=content.split
          fornitore='' if fornitore.nil?
          if ['(g)','(d)'].include?(fornitore)
            record[:libraries] << [sigla,fornitore[1]]
          end
        when 'BID:'
          if content.size==10
            record[:bid]=content
          else
            record[:manifestation_id]=content.to_i
          end
        when 'TI_'
          record[:title]=content
        end
      end
      # puts record.inspect
      record[:libraries].each do |l|
        bib,forn=l
        forn="Dono" if forn=='d'
        forn="Edicola" if forn=='g'
        library_id = siglebib[bib].nil? ? "\\N" : siglebib[bib]
        bid=record[:bid].blank? ? "\\N" : record[:bid]
        mid=record[:manifestation_id].blank? ? "\\N" : record[:manifestation_id]
        fdout.write("#{record[:title]}\t#{bid}\t#{mid}\t#{library_id}\t#{forn}\n")
      end
      # puts rec
      cnt+=1
      # break if cnt>10
    end
    fdout.write("\\.\n")
    fdout.write("UPDATE archivio_periodici a set manifestation_id=cm.manifestation_id from clavis.manifestation cm where cm.bid=a.bid;\n")

    fdout.write("INSERT into serials_admin_table (titolo,note_interne,library_id,manifestation_id) (select title || ' [IMPORTATO DA ARCHIVIO PERIODICI]',provider,library_id,manifestation_id from archivio_periodici ap left join serials_admin_table s using(manifestation_id,library_id) where ap.manifestation_id is not null and s.titolo is null);\n")

    fdout.flush
    tf.close(false)

    config = Rails.configuration.database_configuration
    dbname=config[Rails.env]["database"]
    username=config[Rails.env]["username"]
    cmd="/usr/bin/psql --no-psqlrc --quiet -d #{dbname} #{username} -f #{tf.path}"
    Kernel.system(cmd)
    tf.close(true)

  end
end
