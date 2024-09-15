# coding: utf-8
class Clinic < ActiveRecord::Base
  self.table_name='clinic_actions'

  def Clinic.common_query_conditions(params, table_alias=nil)
    ta = table_alias.nil? ? '' : "#{table_alias}."
    cond = []
    # cond << "#{ta}home_library = #{Clinic.connection.quote(params[:library])}" if !params[:library].blank?

    cond << "#{ta}home_library is not null" if params[:library_id] == 'bct'
    cond << "#{ta}home_library is null" if params[:library_id] == 'non_bct'
    
    cond << "#{ta}home_library_id = #{params[:library_id].to_i}" if params[:library_id].to_i>0
    if !params[:onlyfc].blank?
      case params[:onlyfc]
      when 'true'
        cond << "#{ta}manifestation_id is null"
      when 'false'
        cond << "#{ta}manifestation_id is not null"
      when 'topogr'
        cond << "#{ta}topogr_id is not null"
      end
    end
    cond << "#{ta}bib_type_first=#{Clinic.connection.quote(params[:bib_type_first])}" if !params[:bib_type_first].blank?
    cond << "#{ta}bib_type=#{Clinic.connection.quote(params[:bib_type])}" if !params[:bib_type].blank?
    if !params[:u100_pubblico].blank?
      if params[:u100_pubblico] == 'NULL'
        cond << "#{ta}u100_pubblico IS NULL"
      else
        cond << "#{ta}u100_pubblico ~ #{Clinic.connection.quote(params[:u100_pubblico].split('').join('|'))}" if !params[:u100_pubblico].blank?
      end
    end
    if !params[:pubblico].blank?
      case params[:pubblico]
      when 'a'
        cond << "#{ta}pubblico = 'adulti'"
      when 'g'
        cond << "#{ta}pubblico = 'adulti'"
        cond << "#{ta}u105_4 = 'r'"
      when 'r'
        cond << "#{ta}pubblico = 'ragazzi'"
      end
    end

    cond << "alt_genere ~ '^errato'" if params[:statcol_error] == "t"
    
    if !params[:genere].blank?
      case params[:genere]
      when 'n'
        cond << "#{ta}genere = 'vol_narrativa'"
      when 's'
        cond << "#{ta}genere = 'vol_saggistica'"
      when 'mm'
        cond << "#{ta}genere = 'multimedia'"
      when 'na'
        cond << "#{ta}genere is null"
      end
    end
    if !params[:loans].blank?
      case params[:loans]
      when 'y'
        cond << "#{ta}anni_prestito is not null"
      when 'n'
        cond << "#{ta}anni_prestito is null"
      when 'xxx'
        # cond << "genere is null"
      end
    end
    if !params[:piemonte].blank?
      cond << "#{ta}piemonte is true"
    end

    if !params[:edition_age].blank?
      # Non usato, lo lascio qui per futuri ragionamenti
      cond << "#{ta}print_year between 1500 and date_part('year', now())-#{params[:edition_age].to_i}"
    end

    if !params[:dr_id].blank?
      cond << "dr.id = #{params[:dr_id].to_i}"
    end
    
    if !params[:other_libraries].blank?
      if params[:other_libraries] =~ /^-/
        cond << "#{ta}other_library_count > abs(#{params[:other_libraries].to_i})"
      else
        cond << "#{ta}other_library_count=#{params[:other_libraries].to_i}"
      end
    end

    
    if !params[:statcol].blank?
      (
        tv = params[:statcol]
        # tv.sub('(', '\\(')
        cond << "#{ta}statcol ~ #{self.connection.quote(tv)}"
      )
    end

    if !params[:item_status].blank?
      p=params[:item_status]
      a=p.split('')
      if p[0]=='!'
        a.shift
        cl="NOT IN"
      else
        cl="IN"
      end
      v=a.map {|e| "'#{e}'"}.join(',')
      cond << "#{ta}item_status #{cl} (#{v})"
    end
    cond << "#{ta}item_media=#{self.connection.quote(params[:item_media])}" if !params[:item_media].blank?

    # cond << "#{ta}loan_class=#{self.connection.quote(params[:loan_class])}" if !params[:loan_class].blank?


    if !params[:loan_class].blank?
      p=params[:loan_class]
      a=p.split('')
      if p[0]=='!'
        a.shift
        cl="NOT IN"
      else
        cl="IN"
      end
      v=a.map {|e| "'#{e}'"}.join(',')
      cond << "#{ta}loan_class #{cl} (#{v})"
    end


    
    if !params[:year].blank?
      from,to=params[:year].split('-')
      if from.blank? and !to.blank?
        cond << "#{ta}inventory_date <= '#{to.to_i}-12-31'"
      end
      if !from.blank? and to.blank?
        cond << "#{ta}inventory_date between '#{from.to_i}-01-01' AND '#{from.to_i}-12-31'"
      end
      if !from.blank? and !to.blank?
        cond << "#{ta}inventory_date between '#{from.to_i}-01-01' AND '#{to.to_i}-12-31'"
      end
      # raise "from: #{from} ||| to: #{to}"
    end
    cond = cond.join(' and ')
    cond = "and #{cond}" if !cond.blank?
    cond
  end

  def Clinic.libraries_select(solo_decentrate=nil)
    cond = solo_decentrate.nil? ? '' : 'and lc.clavis_library_id not in (2,3)'
    sql=%Q{select lc.clavis_library_id as key,
        case when lc.topografico is true then lc.label || ' (topografico)' else lc.label || ' (' || substr(cl.label,6) || ')' end as label
         FROM sbct_acquisti.library_codes lc join clavis.library cl on(cl.library_id=lc.clavis_library_id)
            WHERE lc.owner='bct' #{cond} order by lc.label;}
    self.connection.execute(sql).collect {|i| [i['label'],i['key']]}
  end

  def Clinic.onlyfc_select
    [
      ['Escludi fuori catalogo',false],
      ['Solo fuori catalogo',true],
      ['Topografico (non funziona ancora)','topogr'],
    ]
  end

  def Clinic.u100_pubblico_select
    [
      ['giovani (in generale) - a','a'],
      ['prescolare, età 0-5 - b','b'],
      ['elementari, età 6-10 - c','c'],
      ['ragazzi, età 11-15 - d','d'],
      ['giovani, età 16-19 - e','e'],
      ['Ragazzi (b-c-d)','bcd'],
      ['adulti, specialistico - k','k'],
      ['adulti, generale - m','m'],
      ['adulti, intermedio - n','n'],
      ['Adulti (k-m-n)','kmn'],
      ['sconosciuto - u','u'],
      ['non specificato in Clavis','NULL'],
    ]
  end

  def Clinic.pubblico_select
    [
      ['Adulti','a'],
      ['Ragazzi','r'],
      ['Giovani adulti (Letteratura per ragazzi collocata in Narrativa adulti)','g'],
    ]
  end

  def Clinic.genere_select
    [
      ['Volumi narrativa','n'],
      ['Volumi saggistica','s'],
      ['Multimedia','mm'],
    ]
  end

  def Clinic.loans_select
    [
      ['Prestati almeno una volta','y'],
      ['Mai prestati','n'],
    ]
  end

  def Clinic.other_libraries_select
    [
      ['Copia unica',0],
      ['Altra biblioteca',1],
      ['Altre 2 biblioteche',2],
      ['Altre 3 biblioteche',3],
      ['Più di 3 biblioteche',-3],
      ['Più di 5 biblioteche',-5],
      ['Più di 10 biblioteche',-10],
    ]
  end

  def Clinic.ogg_bibl_select(bib_type_first=nil)
    vc = bib_type_first.nil? ? 'OGGBIBL' : "OGGBIBL_#{bib_type_first}"
    sql = "select value_key as key,value_label as label from clavis.lookup_value  where value_class = '#{vc}' and value_language='it_IT'"
    self.connection.execute(sql).collect {|i| key = bib_type_first.nil? ? '' : " - #{i['key']}" ;["#{i['label']}#{key}",i['key']]}
  end
  
end
