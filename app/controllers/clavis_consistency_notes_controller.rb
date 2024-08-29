class ClavisConsistencyNotesController < ApplicationController
  layout 'navbar'

  def index
    @clavis_consistency_note = ClavisConsistencyNote.new(params[:clavis_consistency_note])
    # render text:@clavis_consistency_note.collocazione_per and return
    @clavis_consistency_note['title']=''
    @pagetitle='Archivio periodici con collocazione "Per." in Civica centrale'

    cond=[]
    if !@clavis_consistency_note.collocazione_per.nil?
      cond << "cn.collocazione_per=#{@clavis_consistency_note.collocazione_per}"
    end

    if !params[:per_from_to].blank?
      from,to=params[:per_from_to].split('-')
      cond << "cn.collocazione_per BETWEEN #{from.to_i} AND #{to.to_i}"
    end
    if !@clavis_consistency_note.text_note.nil?
      cond << "cn.text_note ~* #{ClavisConsistencyNote.connection.quote(@clavis_consistency_note.text_note)}"
    end
    cond = cond.size==0 ? '' : "AND #{cond.join(' AND ')}"
    url_sbn_join = 'left join'
    sql=%Q{select cn.collocazione_per,cn.consistency_note_id,cn.collocation,cn.text_note,trim(cm.title) as title,
                cm.manifestation_id,cm.bid,
                 array_agg(pic.cassa) as casse,
   (case
     when url_sbn.url is null
       then ''
       else url_sbn.url
    end) as "URL"

        from clavis.consistency_note cn 
left join clavis.periodici_in_casse pic on(cn.collocazione_per=pic.collocazione_per)
join clavis.manifestation cm using(manifestation_id)
#{url_sbn_join} clavis.url_sbn using(manifestation_id)
        where cn.collocazione_per >0 and library_id = 2 and cn.collocation ~* 'per'
          #{cond}
          group by cn.consistency_note_id,cn.collocation,cn.text_note,trim(cm.title),cm.manifestation_id,url_sbn.url
           order by cn.collocazione_per,replace(lower(cn.collocation),'bct.','')}

    @clavis_consistency_notes=ClavisConsistencyNote.paginate_by_sql(sql,:page=>params[:page], :per_page=>100)
  end

  def list_by_manifestation_id
    if params[:id].blank?
      @clavis_consistency_notes=[]
    else
      @clavis_consistency_notes=ClavisConsistencyNote.where(manifestation_id:params[:id]).order(:library_id)
    end
  end

  def show
    @clavis_consistency_note=ClavisConsistencyNote.find(params[:id])
  end

  def details
    headers['Access-Control-Allow-Origin'] = "*"
    if params[:manifestation_id].blank?
      render :text=>'manifestation_id?' and return
    end
    mid=params[:manifestation_id].to_i
    # @clavis_consistency_note=ClavisConsistencyNote.where("library_id=2 AND manifestation_id=#{mid} AND collocazione_per NOTNULL").first

    sql=%Q{select cn.* from clavis.consistency_note cn, clavis.periodici_in_casse pc
       where cn.library_id=2 AND manifestation_id=#{mid} and
       (cn.collocazione_per=pc.collocazione_per or cn.consistency_note_id=pc.consistency_note_id);}
    @clavis_consistency_note=ClavisConsistencyNote.find_by_sql(sql).first

    if @clavis_consistency_note.nil?
      sql=%Q{select cit.item_title as consistenza, c.label as contenitore, cl.description as deposito,
          ci.loan_alert_note as note, ci.item_id as item_id, c.prenotabile, ci.issue_description
         from clavis.item ci join container_items cit using(item_id,manifestation_id)
       join containers c on(cit.container_id=c.id) join clavis.library cl on(cl.library_id=c.library_id)
       where ci.manifestation_id=#{mid} ORDER BY cit.row_number,cit.item_title}
      @container_items=ContainerItem.find_by_sql(sql)
      # render :text=>'' and return
      render :text=>'' and return if @container_items==[]
      respond_to do |f|
        f.html {render :action=>'/container_items_show'}
        f.js  {render :action=>'/container_items_show', :layout=>false}
      end
      return
    end
    render :text=>'' and return if @clavis_consistency_note.nil?
    respond_to do |f|
      f.html
      f.js  {render :layout=>false}
    end
  end


end
