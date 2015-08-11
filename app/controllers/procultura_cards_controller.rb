class ProculturaCardsController < ApplicationController
  layout 'navbar'
  before_filter :authenticate_user!, only: [:edit, :update]

  def index
    ids=params[:ids]
    if ids.blank?
      q = params[:q].blank? ? '' : params[:q]
      ts=ProculturaCard.connection.quote_string(q.split.join(' & '))
      cond="to_tsvector('simple', heading) @@ to_tsquery('simple', '#{ts}')"
      @procultura_cards=ProculturaCard.paginate(conditions:cond,page:params[:page],per_page:100,order:'lower(heading)')
    else
      k=ids.split.collect {|i| i.to_i}
      @procultura_cards=ProculturaCard.find(k, :order=>'filepath')
    end
    # render :layout=>nil
  end

  def show
    @reqfrom=params[:reqfrom]
    @reqfrom="http://#{@reqfrom.split('?').first}" if !@reqfrom.blank?
    @procultura_card=ProculturaCard.find(params[:id])
    respond_to do |format|
      format.html {
        # render :layout=>nil
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
        img=Magick::Image.read(@procultura_card.cached_filename(:jpg)).first
        # img.resize_to_fit!(800)
        img.resize!(800,491)
        send_data(img.to_blob, :type => 'image/jpeg; charset=binary', :disposition => 'inline')
      }
      format.gif {
        @procultura_card.get_image(:gif)
        send_file(@procultura_card.firstimage_path(:gif), :type => 'graphics/gif', :disposition => 'inline')
      }
      format.js {
        @close = params[:close].blank? ? false : true
      }
    end
  end

  def edit
    @procultura_card=ProculturaCard.find(params[:id])
  end

  def update
    @procultura_card=ProculturaCard.find(params[:id])
    respond_to do |format|
      params[:procultura_card][:updated_by]=current_user
      params[:procultura_card][:updated_at]=Time.now
      if @procultura_card.update_attributes(params[:procultura_card])
        format.html { redirect_to(@procultura_card, :notice => 'ProculturaCard was successfully updated.') }
        format.json { respond_with_bip(@procultura_card) }
      else
        format.html { render :action => "edit" }
        format.json { respond_with_bip(@procultura_card) }
      end
    end
  end

end
