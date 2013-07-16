# -*- mode: ruby;-*-


desc 'Genera files pdf per allegati immagine'

task :generate_pdf => :environment do
  sql=%Q{SELECT DISTINCT attachable_id as mid
     FROM public.attachments
     WHERE attachable_type='ClavisManifestation'
      AND attachment_category_id='C' ORDER BY attachable_id;}
  # puts sql
  mids=[]
  Attachment.connection.execute(sql).each do |res|
    # puts "res: #{res.inspect}"
    mids << res['mid']
  end
  if mids.size==0
    puts "non ci sono allegati"
    exit
  end

  manifestations=ClavisManifestation.find(mids, :order=>'manifestation_id')
  manifestations.each do |cm|
    # puts "#{cm.id} title: #{cm.title[0..12]} - #{cm.attachments.size}"
    cm.attachments_generate_pdf(true,50)
  end

  
end
