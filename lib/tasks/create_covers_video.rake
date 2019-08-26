# -*- mode: ruby;-*-

desc 'Crea un video con le copertine dei libri prestati il giorno prima'

workdir='/home/storage/nowww/comperio_covers_cache'

def recupera_copertine(workdir,ean_and_ids)
  # puts "Prova recupero copertina"
  # puts "wget http://covers.comperio.it/calderone/viewmongofile.php?ean=9788849817843"
  cnt=0
  ean_and_ids.each do |r|
    outfile="/home/storage/nowww/comperio_covers_cache/cover_#{r['manifestation_id']}"
    if File.exists?(outfile)
      next if File.size(outfile)!=0
    end
    cmd="wget -O #{outfile} http://covers.comperio.it/calderone/viewmongofile.php?ean=#{r['EAN']}"
    Kernel.system(cmd)
    if File.size(outfile)>185
      cnt+=1
    end
    # sleep 1
  end
  puts "cnt: #{cnt}"
end

def get_manifestations
  sql=%Q{SELECT cm."EAN", cm.manifestation_id, cc.collocazione, cm.title
  FROM clavis.item ci JOIN clavis.manifestation cm USING(manifestation_id)
    JOIN clavis.collocazioni cc USING(item_id)
     WHERE length(cm."EAN")=13 AND home_library_id = 2
    and loan_status='A' and ci.check_in notnull and manifestation_id!=0 and item_media='F'
    order by ci.check_in DESC limit 200;}
  puts sql
  ClavisManifestation.connection.execute(sql).to_a
end

def etichetta_copertine(workdir,ids_and_collocazione,summary_fd)
  Kernel.system("rm -f #{workdir}/video/???.png")
  cnt=0
  ids_and_collocazione.each do |r|
    summary_fd.write("<tr><td>#{r['collocazione']}</td><td><a href=https://bct.comperio.it/opac/detail/view/sbct:catalog:#{r['manifestation_id']}>#{r['title'].strip}</a></td></tr>\n\n")
    fname="#{workdir}/cover_#{r['manifestation_id']}"
    # puts %Q{#{fname}: #{File.size(fname)} - collocazione: #{r['collocazione']}}
    next if File.size(fname)==185
    # puts "tratto #{fname}"
    cnt+=1
    cmd=%Q{/usr/bin/convert -label '#{r['collocazione']}' #{fname} #{File.join(workdir,'video')}/#{format '%03d',cnt}.png}
    puts cmd
    Kernel.system(cmd)
  end
end

def raggruppa_copertine(workdir)
  fcolors = [
    'SkyBlue',
    'black',
  ]
  Kernel.system("rm -f #{workdir}/video/frame_*.jpg")
  puts "Files da trattare in #{File.join(workdir,'video')}"
  wdir=File.join(workdir,'video')
  cnt=1;outcnt=1
  seq=1;files=[]
  while true do
    fname="#{wdir}/#{format '%03d',cnt}.png"
    break if !File.exists?(fname)
    files << fname
    seq+=1
    if seq > 4
      if (outcnt % 2) == 0
        titolo='Muovi il mouse per accedere al catalogo'
        # bcolor='none'
        # fcolor='SkyBlue'

        bcolor='white'
        fcolor='black'

      else
        bcolor='white'
        fcolor='black'
        titolo="#{Time.now}"
        titolo="Libri da poco restituiti alla biblioteca"
      end
      outfile="#{wdir}/frame_#{format '%02d',outcnt}.jpg"
      # cmd=%Q{/usr/bin/montage #{files.join(' ')} -tile x2 -background none -title '#{titolo}' -shadow #{outfile}}
      cmd=%Q{/usr/bin/montage  #{files.join(' ')} -tile x1 -title '#{titolo}' -background #{bcolor} -fill #{fcolor} -shadow #{outfile}}
      puts cmd
      Kernel.system(cmd)
      outcnt+=1
      seq=1;files=[]
    end
    cnt+=1
  end
  puts "finito"
end

def produci_video(workdir)
  wdir=File.join(workdir,'video')
  outfile='video.mov'
  cmd="cd #{wdir};ffmpeg -y -f image2 -framerate 25 -pattern_type sequence -start_number 1 -r 0.18 -i frame_%02d.jpg #{outfile}"
  puts cmd
  Kernel.system(cmd)
end

def sovrapponi_con_video_di_sfondo(workdir)
  wdir=File.join(workdir,'video')
  cmd="cd #{wdir}; sh ./sovrapponi.sh"
  puts cmd
  Kernel.system(cmd)
end

def create_covers_zipfile(workdir)
  wdir=File.join(workdir, 'video')
  zip_filename="/home/storage/preesistente/static/porteus_screensaver.zip"
  File.delete(zip_filename) if File.exists?(zip_filename)
  Zip::File.open(zip_filename, Zip::File::CREATE) do |zipfile|
    Dir.glob("#{wdir}/frame_*").sort.each do |f|
      zipfile.add(File.basename(f), f)
    end
  end
  puts "Scritto in #{zip_filename}"
end


task :create_covers_video => :environment do
  ean_and_ids=get_manifestations
  recupera_copertine(workdir,ean_and_ids)
  summary_fd=File.open(File.join(workdir, "video", "summary.html"), 'w')
  summary_fd.write(%Q{<!DOCTYPE html><html lang="it"><head><meta charset="utf-8"><title>Elenco libri del salvaschermo</title></head>
<body><h2>Libri del salvaschermo di oggi</h2>
<table>
})
  etichetta_copertine(workdir,ean_and_ids,summary_fd)
  summary_fd.write("</table></body></html>\n")
  summary_fd.close
  raggruppa_copertine(workdir)
  create_covers_zipfile(workdir)
  # produci_video(workdir)
  # sovrapponi_con_video_di_sfondo(workdir)
end
