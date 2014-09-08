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
    end
    render :layout=>false
  end


end
