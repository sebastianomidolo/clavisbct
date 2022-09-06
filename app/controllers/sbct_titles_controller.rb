# coding: utf-8

class SbctTitlesController < ApplicationController
  layout 'sbct'

  before_filter :authenticate_user!
  load_and_authorize_resource

  respond_to :html

  def homepage
    @pagetitle="CR - Home page"
    @sbct_title = SbctTitle.new(params[:sbct_title])
    # render template:'sbct_titles/aggiornamento_in_corso' if current_user.email!='seba'
  end

  def piurichiesti
    @clavis_manifestations=ClavisManifestation.piurichiesti
  end

  def users
    @users = SbctTitle.users
  end

  def new
    @sbct_title = SbctTitle.new
    respond_with(@sbct_title)
  end

  def create
    @sbct_title = SbctTitle.new(params[:sbct_title])
    @sbct_title.created_by = current_user.id
    @sbct_title.save
    respond_with(@sbct_title)
  end

  def index
    @pagetitle="Centro Rete BCT - DB acquisti"
    execsql=false

    if params[:sbct_title].blank?
      @sbct_title = SbctTitle.new()
    else
      @sbct_title = SbctTitle.new(params[:sbct_title])
    end

    @clavis_libraries=current_user.clavis_libraries
    @sbct_budgets=current_user.sbct_budgets
    if !params[:id_lista].blank?
      @sbct_list = SbctList.find(params[:id_lista])
    end

    if !params[:budget_id].blank?
      @sbct_budget = SbctBudget.find(params[:budget_id])
    end
    
    @attrib=@sbct_title.attributes.collect {|a| a if not a.last.blank?}.compact
    toskip=["id_titolo"]
    @attrib.delete_if do |r|
      toskip.include?(r.first)
    end
    cond=[]
    @msg = []
    # @sbct_titles = SbctTitle.paginate_by_sql("SELECT * FROM #{SbctTitle.table_name} WHERE false", :page=>1);
    @attrib.each do |a|
      name,value=a
      case name
      when 'titolo'
        ts=SbctTitle.connection.quote_string(value)
        cond << %Q{#{SbctTitle.fulltext_attributes('t.')} @@ plainto_tsquery('simple', '#{ts}')}
      when 'wrk'
        ts=SbctTitle.connection.quote(value)
        cond << "#{name} = #{ts}"
      when 'def'
        ts=SbctTitle.connection.quote(value)
        cond << "#{name} = #{ts}"
      else
        ts=SbctTitle.connection.quote_string(value)
        cond << "#{name} ~* '#{ts}'"
      end
    end
    cond << "l.id_tipo_titolo = '#{params[:tipo_titolo]}'" if !params[:tipo_titolo].blank?
    cond << "tl.id_lista = '#{params[:id_lista]}'" if !params[:id_lista].blank?

    if @sbct_title.clavis_library_ids.blank?
      join_type_libraries = 'LEFT'
    else
      join_type_libraries = ''
      execsql=true
      cond << "cp.library_id IN (#{@sbct_title.clavis_library_ids.join(',')})"
    end
    if !params[:con_copie].blank?
      join_type_libraries = ''
    end

    if !@sbct_list.nil? or not params[:tipo_titolo].blank?
      join_lists = 'JOIN sbct_acquisti.liste l using(id_lista)'
      join_l_titoli_liste = "left join sbct_acquisti.l_titoli_liste tl using(id_titolo)"
      cond << "l.id_lista = #{@sbct_list.id}" if params[:tipo_titolo].blank?
    else
      # join_lists = 'JOIN sbct_acquisti.liste l using(id_lista)'
      join_l_titoli_liste = join_lists = ''
    end

    if @sbct_budget.nil?
      join_budgets = ''
    else
      if !params[:con_copie].blank?
        join_budgets = 'LEFT JOIN sbct_acquisti.budgets b on(b.budget_id=cp.budget_id)'
        cond << "b.budget_id = #{@sbct_budget.id}"
      else
        cond << "cp.id_titolo in (select id_titolo from sbct_acquisti.copie where budget_id=#{@sbct_budget.id})"
      end
    end

    if params[:con_richieste_lettori].blank?
      select_lettori = join_lettori = ''
    else
      execsql=true
      select_lettori = 'array_agg(al.id_lettore),'
      join_lettori = "JOIN cr_acquisti.acquisti_lettore al on (al.id_acquisti=t.id_titolo)"
    end

    if params[:pproposal].blank?
      select_pproposal = join_pproposal = group_pproposal = ''
    else
      execsql = true
      select_pproposal = 'pp.proposal_id,'
      group_pproposal = ',pp.proposal_id'
      join_pproposal = "JOIN clavis.purchase_proposal pp on(pp.status='A' AND (pp.ean != '' AND (pp.ean = t.ean or pp.ean = t.isbn)))"
    end

    cond << "manifestation_id is not null" if !params[:in_clavis].blank?

    cond << "manifestation_id is null" if !params[:non_in_clavis].blank?

    cond << "reparto is not  null" if !params[:con_reparto].blank?

    cond << "cp.order_status = #{@sbct_title.connection.quote(params[:order_status])}" if !params[:order_status].blank?
    #render text:cond.inspect and return
    #render text:Time.now and return

    order_by = execsql == true ? 'order by t.autore,t.titolo' : nil

    case (params[:order])
    when '1'
      order_by = 'order by t.autore,t.titolo'
    when '2'
      order_by = 'order by t.editore,t.autore,t.titolo'
    when '3'
      order_by = 'order by t.id_titolo desc'
    when '4'
      order_by = 'order by t.prezzo,t.autore,t.titolo'
    when '5'
      order_by = 'order by numcopie desc, library_ids'
    when '6'
      order_by = 'order by t.anno desc,t.autore,t.titolo'
      cond << "t.anno notnull"
    when '7'
      order_by = 'order by t.datapubblicazione desc,t.anno desc,t.autore,t.titolo'
      cond << "t.datapubblicazione notnull"
    when '8'
      order_by = 'order by random()'
    when ''
      order_by = ''
    end

    cond = cond.join(" AND ")

    cond = execsql.to_s if cond.blank?
    cond = "WHERE #{cond}" 

    @msg = "execsql: #{execsql} - cond: #{cond}"

    
    per_page = params[:per_page].blank? ? 200 : params[:per_page]

    @sql=%Q{
select t.id_titolo,t.collana,t.autore,t.titolo,t.editore,t.manifestation_id,#{select_lettori}t.prezzo,t.isbn,t.anno,t.datapubblicazione,#{select_pproposal}
array_to_string(array_agg(distinct cp.library_id),',') as library_ids,
array_to_string(array_agg(distinct lcod.label order by lcod.label),',') as library_codes,
array_length(array_agg(cp.library_id),1) as numcopie,
count(*)
 from sbct_acquisti.titoli t
 #{join_l_titoli_liste}
 #{join_lists}
 #{join_lettori}
 #{join_type_libraries} join sbct_acquisti.copie cp using(id_titolo)
 #{join_type_libraries} join sbct_acquisti.library_codes lcod on (lcod.clavis_library_id = cp.library_id)
 #{join_pproposal}
 #{join_budgets}
     #{cond}
     group by t.id_titolo,t.autore,t.titolo,t.editore,t.manifestation_id,t.prezzo,t.isbn,t.anno,t.datapubblicazione#{group_pproposal}
    #{order_by}
    }
    fd=File.open("/home/seb/sbct_titles.sql", "w")
    fd.write(@sql)
    fd.close

    # render text:"@sql: #{@sql}" and return

    @sbct_titles = SbctTitle.paginate_by_sql(@sql, page:params[:page], per_page:100)

    # render text:@sbct_titles.total_entries and return

    if params[:nolist].blank?
      @pagetitle="Acquisti"
      # @sbct_titles = nil
    else
      @pagetitle="Titoli senza data libri (fuori lista)"
      @sbct_titles = SbctTitle.without_list
      @sbct_titles = @sbct_titles.paginate(page:params[:page], per_page:100)
    end

    respond_to do |format|
      format.html { respond_with(@sbct_titles) }
      format.csv {
        require 'csv'
        @sbct_titles = SbctTitle.find_by_sql(@sql)
        csv_string = CSV.generate({col_sep:",", quote_char:'"'}) do |csv|
          csv << ['autore','titolo','editore','collana','prezzo','isbn']
          @sbct_titles.each do |r|
            csv << [r.autore,r.titolo,r.editore,r.collana,r.prezzo,r.isbn]
          end
        end
        send_data csv_string, type: Mime::CSV, disposition: "attachment; filename=text.csv"
      }
    end

  end

  def edit
    @sbct_title=SbctTitle.find(params[:id])
    @pagetitle="Modifica scheda acquisti #{@sbct_title.id}"
  end

  def update
    @sbct_title = SbctTitle.find(params[:id])
    respond_to do |format|
      if @sbct_title.update_attributes(params[:sbct_title])
        @sbct_title.updated_by=current_user.id
        @sbct_title.save
        flash[:notice] = "Modifiche salvate"
        format.html { respond_with(@sbct_title) }
      else
        format.html { render :action => "edit" }
      end
    end
  end

  def show
    @sbct_title=SbctTitle.find(params[:id])
    @pagetitle="Scheda acquisti #{@sbct_title.id}"
    @cr_title = SbctTitle.find_by_sql("select * from cr_acquisti.acquisti where id=#{@sbct_title.id}").first
    # @sbct_clavis_libraries = @sbct_title.sbct_clavis_libraries
    @esemplari_presenti_in_clavis = @sbct_title.esemplari_presenti_in_clavis
  end

  def add_to_library
    @clavis_library=ClavisLibrary.find(params[:library_id])
    @sbct_title=SbctTitle.find(params[:id])
    @sbct_list = SbctList.find(params[:id_lista])
    @sbct_budget = @sbct_list.budget(@clavis_library.id)
    # @error="Per #{@clavis_library.id} budget #{@sbct_budget.id}"
    @sbct_supplier = @sbct_budget.sbct_supplier
    if @sbct_supplier.nil?
      # @error="La lista d'acquisto #{@sbct_list.to_label} non ha fornitore associato - Budget: #{@sbct_budget.label}"
      supplier_id='NULL'
    else
      supplier_id=@sbct_supplier.id
    end
    if current_user.clavis_libraries.include?(@clavis_library)
      if !@sbct_budget.nil? and !current_user.sbct_budgets.include?(@sbct_budget) 
        @error="Il budget richiesto non è tra quelli su cui puoi operare"
      end
    else
      @error="La biblioteca richiesta non è tra quelle su cui puoi operare"
    end
    if @sbct_budget.nil?
      sql = "select b.* from sbct_acquisti.budgets b join sbct_acquisti.l_budgets_libraries using(budget_id) where not b.locked and clavis_library_id=#{@clavis_library.library_id};"
      @sbct_budget=SbctBudget.find_by_sql(sql).first
    end
        
    if @error.nil?
      if params[:checked]=='true'
        @sbct_title.connection.execute("insert into sbct_acquisti.copie (id_titolo, supplier_id, budget_id, library_id, created_by, order_status) values (#{@sbct_title.id},#{supplier_id},#{@sbct_budget.id},#{@clavis_library.id},#{current_user.id},'P')");
        @sbct_title.sbct_items.collect {|r| r.save}
      else
        @sbct_title.connection.execute("delete from sbct_acquisti.copie where id_titolo=#{@sbct_title.id} and library_id=#{@clavis_library.id} and budget_id=#{@sbct_budget.id} and order_status!='A'");
      end
    end
    # @sbct_list_totale = SbctList.totale_ordine(@sbct_title.sbct_list_ids)
    # @sbct_list_totale = @sbct_list.totale_ordine
    respond_to do |format|
      format.html {
      }
      format.js {
      }
    end
  end


  
end
