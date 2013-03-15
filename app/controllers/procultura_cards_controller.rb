class ProculturaCardsController < ApplicationController

  def index
    ids=params[:ids]
    k=ids.split.collect {|i| i.to_i}
    @procultura_cards=ProculturaCard.find(k, :order=>'filepath')
    render :layout=>nil
  end

  def show
    @reqfrom=params[:reqfrom]
    @reqfrom="http://#{@reqfrom.split('?').first}" if !@reqfrom.blank?
    @procultura_card=ProculturaCard.find(params[:id])
    respond_to do |format|
      format.html {
        render :layout=>nil
      }
      format.pdf {
        filename=@procultura_card.intestazione.downcase.gsub(' ', '')
        fn=File.join(ProculturaCard.storagepath,@procultura_card.filepath)
        pdf=File.read(fn)
        send_data(pdf,
                  :filename=>filename,:disposition=>'inline',
                  :type=>'application/pdf')
      }
      format.png {
        @procultura_card.get_image(:png)
        send_file(@procultura_card.firstimage_path(:png), :type => 'graphics/png', :disposition => 'inline')
      }
      format.jpeg {
        @procultura_card.get_image(:jpg)
        send_file(@procultura_card.firstimage_path(:jpg), :type => 'graphics/jpg', :disposition => 'inline')
      }
      format.gif {
        @procultura_card.get_image(:gif)
        send_file(@procultura_card.firstimage_path(:gif), :type => 'graphics/gif', :disposition => 'inline')
      }
    end
  end
end
