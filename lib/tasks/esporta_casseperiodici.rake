# -*- mode: ruby;-*-

desc 'Esportazione lista periodici in casse su google drive'

task :esporta_casseperiodici => :environment do

  spreadsheet_name='Elenco periodici in cassa - Strada del Portone'

  config = Rails.configuration.database_configuration
  username=config[Rails.env]["google_drive_login"]
  passwd=config[Rails.env]["google_drive_passwd"]
  session = GoogleDrive.login(username, passwd)
  spr=session.spreadsheet_by_title(spreadsheet_name)
  spr=session.create_spreadsheet(spreadsheet_name) if spr.nil?
  ws=spr.worksheets.first
  ws.title="Elenco per collocazione e numero di catena"

  sql=%Q{SELECT collocazione_per,catena,trim(catena_string) as catena_string,trim(cassa)
     as cassa,trim(annata) as annata,trim(note) as note from casse_periodici
             ORDER BY collocazione_per,catena;}

  cnt=1
  ws.update_cells(cnt,1,[['Collocazione','Consistenza','Cassa','Annata','Note']])
  prec_coll=nil
  prec_cassa=nil
  catene={}
  ClavisManifestation.find_by_sql(sql).each do |cm|
    next if cm.catena.nil?
    if prec_coll!=cm.collocazione_per
      ar=cm.attribute_names.collect {|n| cm[n]}
      output=[]
      catene.each_pair do |hkey,v|
        actual = v.first
        new_array=v.slice_before do |e|
          expected, actual = actual.next, e
          expected != actual
        end.to_a
        consistenza=[]
        new_array.each do |r|
          if r.size==1
            consistenza << r.first
          else
            consistenza << "#{r.first}-#{r.last}"
          end
        end
        # puts "Collocazione #{prec_coll} => hkey #{hkey}: #{consistenza.join('; ')}"
        cassa,annata,note=hkey
        output << [cassa,annata,note,consistenza.join('; ')]
      end

      # Sparo fuori i risultati
      puts "\nPer la collocazione #{prec_coll}:"
      output.each do |cassa,annata,note,consistenza|
        puts "#{cnt} cassa #{cassa} #{annata} #{note} => #{consistenza}"
        cnt+=1
        # ws.update_cells(cnt,1,[[prec_coll, "'#{consistenza}", cassa,annata,note]])
      end
      puts "---------------------------"

      prec_coll=cm.collocazione_per
      catene={}
    end
    if prec_cassa!=cm.cassa
      prec_cassa=cm.cassa
    end
    catena=cm.catena.to_i
    cm.annata=nil if cm.annata=='*'

    hkey=[cm.cassa,cm.annata,cm.note]

    catene[hkey]=[] if catene[hkey].nil?
    catene[hkey] << cm.catena
  end
  ws.save
end
