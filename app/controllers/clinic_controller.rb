# coding: utf-8
class ClinicController < ApplicationController
  layout 'clinic'
  before_filter :authenticate_user!

  def index
    if params[:rep].blank?
      @records = Clinic.find_by_sql("select id,trim(reparto) as reparto,trim(azione) as azione, trim(description) as description from public.clinic_actions where attivo order by reparto,azione")
      render action:'reception'
      return
    end
    if params[:rep].blank?
      # render text:"menu dei reparti"
    end
    if params[:rep] == 'patrons'
      redirect_to "https://clavisbct.comperio.it/clavis_patrons/duplicates" if params[:sub]=='duplicati'
    end

    if params[:rep] == 'stats'
      cond = Clinic.common_query_conditions(params)
      # render text:"condizioni: #{cond}" and return
      case params[:sub]
      when 'nonclassif'
        @sql = %Q{select t.manifestation_id,
case when t.topogr_id is null then t.item_id else t.topogr_id::integer end as item_id,
case when t.topogr_id is null then false else true end as topografico,
t.colloc_stringa,t.statcol,t.item_status_label from stats.new_patrimonio t
             left join stats.statcols sc using(statcol) where statcol is not null #{cond} and t.statcol = #{Clinic.connection.quote(params[:statcol])}}
        @clavis_items = ClavisItem.paginate_by_sql(@sql, page:params[:page])
        render action:'items_list'

      when 'void_colloc'
        @sql = %Q{select t.manifestation_id,t.item_id,t.colloc_stringa,t.statcol,t.item_status_label, false as topografico from stats.new_patrimonio t
             where manifestation_id is not null and primo_elemento_collocazione is null}
        @clavis_items = ClavisItem.paginate_by_sql(@sql, page:params[:page])
        render action:'items_list'
      when 'patrimonio'
        if !params[:smusi].blank?
          @sql = %Q{select dr.*,si.edition_date,si.class_code,si.statcol,si.ultimo_prestito,si.item_id,si.title,
          case when ui.item_id is null then false else true end as copia_unica,
        si.colloc_stringa,si.anni_prestito,si.prestiti
   from import.super_items si join discard_rules dr on
(
   (
     ultimo_prestito is null or
      (date_part('year',now()) - date_part('year', si.ultimo_prestito)) > dr.anni_da_ultimo_prestito
   )
     and (date_part('year',now())-si.edition_date) > dr.edition_age
)
         left join clavis.unique_items ui on(ui.item_id=si.item_id)
     where
     si.colloc_stringa ~ concat('^' || dr.classe)
      #{cond} order by dr.classe limit 300;}
          @records = Clinic.connection.execute(@sql).to_a
          render action:'scarto'
        else
          @sql = %Q{select pubblico,p.statcol,s.statcol as ghost_statcol,sum(p.prestiti) as numprestiti,count(*)
            from stats.new_patrimonio p left join stats.statcols s using(statcol)
              where statcol is not null #{cond} group by 1,2,3 order by 1,2,3}
          @records = Clinic.connection.execute(@sql).to_a
          render action:'riepilogo_patrimonio'
        end
      else
        render action:'error'
      end
      return
    end

    if params[:rep] == 'authorities'
      case params[:sub]
      when 'clean_spaces'
        redirect_to 'https://clavisbct.comperio.it/clavis_authorities?utf8=%E2%9C%93&sort=&authority_type=C&bidnotnull=&no_bncf=&rectype=&qs=%5E+'
      else
        render action:'error'
      end
    end
    
    if params[:rep] == 'items'
      # redirect_to "https://clavisbct.comperio.it/clavis_items?utf8=%E2%9C%93&piano=&order=&location=&clavis_item%5Btitle%5D=pazienz%40&clavis_item%5Bcollocation%5D=&clavis_item%5Binventory_number%5D=&clavis_item%5Binventory_serie_id%5D=&clavis_item%5Bmanifestation_dewey%5D=&clavis_item%5Bacquisition_year%5D=&clavis_item%5Bpublication_year%5D=&clavis_item%5Bhome_library_id%5D=3&location=&cover_images=&ean_presence=&clavis_item%5Bin_container%5D=0&clavis_item%5Bcreated_by%5D=&clavis_item%5Bmodified_by%5D=&clavis_item%5Bitem_status%5D=&clavis_item%5Bitem_media%5D=&clavis_item%5Bloan_status%5D=&clavis_item%5Bloan_class%5D=&clavis_item%5Bitem_source%5D=&clavis_item%5Bopac_visible%5D=&shelf_id=&commit=cerca"

      # sql = %Q{select p.statcol,count(*) from stats.new_patrimonio p left join stats.statcols s using(statcol) where s is null group by 1 order by p.statcol;}


      case params[:sub]
      when 'inv_eq_colloc'
        redirect_to "https://clavisbct.comperio.it/clavis_items?utf8=%E2%9C%93&piano=&order=&location=&clavis_item%5Btitle%5D=%40inv_eq_colloc&clavis_item%5Bcollocation%5D=&clavis_item%5Binventory_number%5D=&clavis_item%5Binventory_serie_id%5D=&clavis_item%5Bmanifestation_dewey%5D=&clavis_item%5Bacquisition_year%5D=&clavis_item%5Bpublication_year%5D=&clavis_item%5Bhome_library_id%5D=0&cover_images=&ean_presence="
      when 'title_eq_colloc'
        redirect_to "https://clavisbct.comperio.it/clavis_items?utf8=%E2%9C%93&piano=&order=&location=&clavis_item%5Btitle%5D=pazienz%40&clavis_item%5Bcollocation%5D=&clavis_item%5Binventory_number%5D=&clavis_item%5Binventory_serie_id%5D=&clavis_item%5Bhome_library_id%5D=0"

      when 'scarto'
        # Da fare
        render action:'scarto'

      when 'empty_barcodes'
        @sql = %Q{select substr(ci.title,1,40) as statcol,ci.item_id,ci.manifestation_id,ci.home_library_id, false as topografico,
            NULL as colloc_stringa, NULL as item_status_label
             from import.item ci where ci.item_status!='E' and 
         (ci.barcode is null or ci.barcode = '') order by ci.item_id}

        @clavis_items = ClavisItem.paginate_by_sql(@sql, page:params[:page], per_page:400)
        render action:'items_list'

        
      when 'x'
        @sql = %Q{select t.manifestation_id,t.item_id,t.colloc_stringa,t.item_status_label,t.statcol from stats.new_patrimonio t
              left join stats.statcols sc using(statcol) where t.statcol not in ('rag_check') and sc is null order by t.statcol,item_id}
        @clavis_items = ClavisItem.paginate_by_sql(@sql, page:params[:page], per_page:100)
        render action:'items_list'
      else
        render action:'error'
      end
    end
    
  end

end
