
class IssPagesController < ApplicationController
  layout 'iss_journals'

  def index
    qs=params[:qs]
    @cond=[]
    if !qs.blank?
      qs_saved=String.new(qs)
      qs.gsub!(' ', '<->') if qs =~ /^\"/
      qs.gsub!('"','')
      ts=IssPage.connection.quote_string(qs.split.join(' & '))
      params[:qs]=qs_saved
      @cond << %Q{to_tsvector('simple', o.tags::text) @@ to_tsquery('simple', '#{ts}')}
    end
    @cond = @cond.join(" AND ")
    order_by = 'order by j.title, i.annata, a.title, p.position, p.imagepath'
    @cond = 'false' if @cond.blank?
    @sql=%Q{SELECT i.annata || '-' || i.fascicolo as annata,a.title as article_title,j.title as journal_title,
          j.id as journal_id,
          i.id as issue_id,
          a.id as article_id, p.*
        FROM d_objects o JOIN attachments atc on (attachable_type='IssPage' AND d_object_id=o.id)
             JOIN iss.pages p on (p.id=atc.attachable_id)
             JOIN iss.articles a on(a.id=p.article_id)
             JOIN iss.issues i on(i.id=a.issue_id)
             JOIN iss.journals j on(j.id=i.journal_id)
             WHERE #{@cond} #{order_by}}

    @iss_pages = IssPage.paginate_by_sql(@sql,:page=>params[:page], :per_page=>25)

  end


  
  def show
    @iss_page=IssPage.find(params[:id])
    @iss_page.fulltext_store if @iss_page.fulltext.blank?

    respond_to do |format|
      format.html
      format.jpeg {
        if @iss_page.d_object.nil?
          render text:'immagine non trovata' and return
        end
        fn=@iss_page.d_object.get_pdfimage
        img=Magick::Image.read(fn).first
        if !params[:size].blank?
          s=params[:size].split('x')
          img.resize_to_fit!(s[0].to_i)
        end
        send_data(img.to_blob, :type => 'image/jpeg; charset=binary', :disposition => 'inline')
      }
      format.pdf {
        send_file(@iss_page.diskfilename, :filename=>"{@iss_page.to_label}.pdf",
                  :type=>'application/pdf', :disposition => 'inline')
      }
    end
  end

end
