class ProculturaCardsController < ApplicationController
  def show
    @reqfrom=params[:reqfrom]
    @reqfrom="http://#{@reqfrom.split('?').first}" if !@reqfrom.blank?
    @procultura_card=ProculturaCard.find(params[:id])
    respond_to do |format|
      format.html {
        render :layout=>nil
      }
      format.pdf {
        filename=@procultura_card.heading.downcase.gsub(' ', '')
        fn=File.join(ProculturaCard.storagepath,@procultura_card.filepath)
        pdf=File.read(fn)
        send_data(pdf,
                  :filename=>filename,:disposition=>'inline',
                  :type=>'application/pdf')
      }
      format.png {
        filename="/tmp/prova.png"
        data=File.read(filename)
        send_data(data,
                  :filename=>filename,:disposition=>'inline',
                  :type=>'graphics/png')
      }
    end
  end
end
