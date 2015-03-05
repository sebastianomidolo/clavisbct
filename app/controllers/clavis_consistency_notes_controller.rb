class ClavisConsistencyNotesController < ApplicationController
  layout 'navbar'

  def index
    @clavis_consistency_note = ClavisConsistencyNote.new(params[:clavis_consistency_note])
    @clavis_consistency_note['title']=''
    @pagetitle='Verifica note di consistenza per Civica centrale'

    cond=[]
    if !@clavis_consistency_note.collocazione_per.nil?
      cond << "cn.collocazione_per=#{@clavis_consistency_note.collocazione_per}"
    end
    if !@clavis_consistency_note.text_note.nil?
      cond << "cn.text_note ~* #{ClavisConsistencyNote.connection.quote(@clavis_consistency_note.text_note)}"
    end
    cond = cond.size==0 ? '' : "AND #{cond.join(' AND ')}"
    sql=%Q{select cn.collocazione_per,cn.consistency_note_id,cn.collocation,cn.text_note,trim(cm.title) as title,
                cm.manifestation_id,
                 array_agg(pic.cassa) as casse
        from clavis.consistency_note cn 
left join clavis.periodici_in_casse pic on(cn.collocazione_per=pic.collocazione_per)
join clavis.manifestation cm using(manifestation_id)
        where cn.collocazione_per >0 and library_id = 2 and cn.collocation ~* 'per'
          #{cond}
          group by cn.consistency_note_id,cn.collocation,cn.text_note,trim(cm.title),cm.manifestation_id
           order by cn.collocazione_per,replace(lower(cn.collocation),'bct.','')}
    @clavis_consistency_notes=ClavisConsistencyNote.paginate_by_sql(sql,:page=>params[:page], :per_page=>100)
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
    respond_to do |f|
      f.html
      f.js  {render :layout=>false}
    end
  end


end
