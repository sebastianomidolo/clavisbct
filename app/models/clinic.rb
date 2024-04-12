# coding: utf-8
class Clinic < ActiveRecord::Base
  self.table_name='clinic_actions'

  def Clinic.common_query_conditions(params)
    cond = []
    cond << "home_library = #{Clinic.connection.quote(params[:library])}" if !params[:library].blank?
    if !params[:onlyfc].blank?
      case params[:onlyfc]
      when 'true'
        cond << "manifestation_id is null"
      when 'false'
        cond << "manifestation_id is not null"
      when 'topogr'
        cond << "owner_library_id = -1"
      end
    end
    if !params[:pubblico].blank?
      case params[:pubblico]
      when 'a'
        cond << "pubblico = 'adulti'"
      when 'r'
        cond << "pubblico = 'ragazzi'"
      end
    end
    if !params[:genere].blank?
      case params[:genere]
      when 'n'
        cond << "genere = 'narrativa'"
      when 's'
        cond << "genere = 'saggistica'"
      when 'na'
        cond << "genere is null"
      end
    end
    if !params[:loans].blank?
      case params[:loans]
      when 'y'
        cond << "anni_prestito is not null"
      when 'n'
        cond << "anni_prestito is null"
      when 'xxx'
        # cond << "genere is null"
      end
    end
    if !params[:statcol].blank?
      cond << "statcol ~ #{self.connection.quote(params[:statcol])}"
    end

    cond << "item_status=#{self.connection.quote(params[:item_status])}" if !params[:item_status].blank?
    cond << "item_media=#{self.connection.quote(params[:item_media])}" if !params[:item_media].blank?
    cond << "loan_class=#{self.connection.quote(params[:loan_class])}" if !params[:loan_class].blank?
    if !params[:year].blank?
      from,to=params[:year].split('-')
      if from.blank? and !to.blank?
        cond << "inventory_date <= '#{to.to_i}-12-31'"
      end
      if !from.blank? and to.blank?
        cond << "inventory_date between '#{from.to_i}-01-01' AND '#{from.to_i}-12-31'"
      end
      # raise "from: #{from} ||| to: #{to}"
    end
    cond = cond.join(' and ')
    cond = "and #{cond}" if !cond.blank?
    cond
  end

  def Clinic.libraries_select
    sql=%Q{select lc.label as key,
        case when lc.topografico is true then lc.label || ' (topografico)' else lc.label || ' (' || substr(cl.label,6) || ')' end as label
         FROM sbct_acquisti.library_codes lc join clavis.library cl on(cl.library_id=lc.clavis_library_id)
            WHERE lc.owner='bct' order by lc.label;}
    self.connection.execute(sql).collect {|i| [i['label'],i['key']]}
  end

end
