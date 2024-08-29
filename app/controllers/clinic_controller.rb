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
    # if params[:rep] == 'patrons'
    #  redirect_to "https://clavisbct.comperio.it/clavis_patrons/duplicates" if params[:sub]=='duplicati'
    # end

    if params[:rep] == 'stats'
      cond = Clinic.common_query_conditions(params)
      # render text:"condizioni: #{cond}" and return
      case params[:sub]
      when 'nonclassif'
        @sql = %Q{select t.manifestation_id,t.title,t.home_library,t.home_library_id,
case when t.topogr_id is null then t.item_id else t.topogr_id::integer end as item_id,
case when t.topogr_id is null then false else true end as topografico,
t.colloc_stringa,t.statcol,t.item_status_label from import.super_items t
             left join stats.statcols sc using(statcol) where statcol is not null #{cond}
     and t.statcol = #{Clinic.connection.quote(params[:statcol])}
      order by t.colloc_stringa}
        @clavis_items = ClavisItem.paginate_by_sql(@sql, page:params[:page])
        render action:'items_list'

      when 'void_colloc'
        @sql = %Q{select t.title,t.manifestation_id,t.item_id,t.colloc_stringa,t.statcol,t.item_status_label, false as topografico,
                t.home_library
              from import.super_items t
             where manifestation_id is not null and t.colloc_stringa = '' and t.item_status!='A'
              and t.home_library notnull}
        @clavis_items = ClavisItem.paginate_by_sql(@sql, page:params[:page])
        render action:'items_list'
      when 'patrimonio'
        @pagetitle='Selezione per scarto'
        if !params[:smusi].blank?
          cond = Clinic.common_query_conditions(params, 'si')
          if params[:genere]=='s'
            # class_code_cond =  "and si.colloc_stringa ~ concat('^' || rtrim(dr.classe,'0')) and dr.genere is null and dr.pubblico is null"
            # class_code_cond =  "and si.dw3 between dr.classe_from and dr.classe_to"
          else
            pubcond = params[:pubblico].blank? ? '' : "and si.pubblico = dr.pubblico"
            # gencond = params[:genere].blank? ? '' : "and si.genere = dr.genere"
            gencond = ''
          end
          @sql = %Q{select dr.id as dr_id, dr.classe as dr_classe,
                    dr.descrizione as dr_descrizione, dr.edition_age as dr_edition_age,
                    dr.anni_da_ultimo_prestito as dr_anni_da_ultimo_prestito,
si.edition_date,si.class_code,si.statcol,si.ultimo_prestito,si.item_id,substr(si.title,1,80) as title,si.manifestation_id,
          case when si.other_library_count = 0 then true else false end as copia_unica,
           si.barcode,si.inventory_date,
        si.colloc_stringa,si.anni_prestito,si.prestiti,NULL as loc_name,NULL as section,si.colloc_stringa as collocation,
        NULL as specification,NULL as sequence1, NULL as sequence2,
        si.inventory_serie_id,si.inventory_number,
        si.anni_prestito_totale,si.prestiti_totale,
        si.reprint_year, si.reprint, si.print_year, array_to_string(si.other_library_labels,', ') as other_library_labels, si.other_library_count
   from import.super_items si join clavis.item ci using(item_id) 
         join import.collocazioni cc using(item_id)
         join import.discardable_items as dr using(item_id)

     where
        dr.item_id is not null
        #{pubcond}
        #{gencond}

      #{cond} order by cc.sort_text
      }
          # raise "sql #{@sql}"
          respond_to do |format|
            format.html {
              @records = Clinic.paginate_by_sql(@sql, page:params[:page], per_page:300)
              render action:'scarto'
            }
            format.csv {
              require 'csv'
              @records = Clinic.find_by_sql(@sql)
              csv_string = CSV.generate({col_sep:",", quote_char:'"'}) do |csv|
                # csv << ['barcode','collocazione']
                @records.each do |r|
                  csv << [r.barcode]
                end
              end
              send_data csv_string, type: Mime::CSV, disposition: "attachment; filename=barcodes.csv"
            }
            format.pdf {
              @clavis_items = ClavisItem.find_by_sql(@sql)
              # heading = params[:heading].blank? ? "Elenco libri a magazzino" : params[:heading]
              heading = "Attenzione! non effettuare lo scarto sulla base di questo elenco"
              @clavis_items.define_singleton_method(:titolo_elenco) do
                heading
              end
              pdf_template='scarto'
              filename="#{@clavis_items.size}_#{pdf_template}.pdf"
              lp=LatexPrint::PDF.new(pdf_template, @clavis_items, false)
              send_data(lp.makepdf,
                        :filename=>filename,:disposition=>'inline',
                        :type=>'application/pdf')
            }
          end
        else
          @pagetitle='Analisi patrimonio (statcol)'
          @sql = %Q{select pubblico,p.statcol,s.statcol as ghost_statcol,sum(p.prestiti) as numprestiti,count(*)
            from import.super_items p left join stats.statcols s using(statcol)
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

    if params[:rep] == 'patrons'
      case params[:sub]
      when 'utenti_duplicati'
        redirect_to "https://clavisbct.comperio.it/clavis_patrons/duplicates"
      when 'altro'        
      else
        raise "errore: #{params[:rep]} - "
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

      when 'empty_barcodes'
        @sql = %Q{select si.title,substr(si.title,1,40) as statcol,ci.item_id,ci.manifestation_id,ci.home_library_id, false as topografico,
            NULL as colloc_stringa, NULL as item_status_label
             from import.super_items si join import.item ci using(item_id) where ci.item_status!='E' and 
         (ci.barcode is null or ci.barcode = '') order by ci.item_id}
        @clavis_items = ClavisItem.paginate_by_sql(@sql, page:params[:page], per_page:400)

        render action:'items_list'
        
      when 'rist_volume_text'
        @sql = %Q{select ci.title,ci.item_id,ci.reprint,ci.manifestation_id,ci.home_library_id, si.edition_date,ci.volume_text
from import.super_items si join import.item ci using(item_id)
where si.reprint is null and ci.volume_text ~* '(ristampa|rist).*[12][0-9]{3}'
-- and si.home_library_id=2 
-- and si.loan_class='B'
}
        
        @clavis_items = ClavisItem.paginate_by_sql(@sql, page:params[:page], per_page:400)

        render action:'simple_items_list'

      when 'scarto'
        raise 'codice per lo scarto da inserire qui'
        
      when 'x'
        @sql = %Q{select t.title,t.manifestation_id,t.item_id,t.colloc_stringa,t.item_status_label,t.statcol,false as topografico
           from import.super_items t
              left join stats.statcols sc using(statcol) where t.statcol not in ('rag_check') and sc is null order by t.statcol,item_id}
        @clavis_items = ClavisItem.paginate_by_sql(@sql, page:params[:page], per_page:100)
        render action:'items_list'
      else
        render action:'error'
      end
    end
    
  end

end
