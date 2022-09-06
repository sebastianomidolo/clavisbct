# coding: utf-8
module SerialTitlesHelper

  def serial_titles_list_readonly(records)
    res=[]; cnt=0
    records.each do |r|
      note = r.note.blank? ? '' : "<br/>Nota interna: <em>#{r.note}</em>"
      freq = r.frequency_label.blank? ? '' : " [<em>#{r.frequency_label}</em>]"

      mytit = "#{r.title}#{freq}"
      title = r.manifestation_id.nil? ? r.title : link_to(mytit.html_safe, ClavisManifestation.clavis_url(r.manifestation_id), {class:'',target:'_new'})

      libraries = params[:library_id].blank? ? SerialSubscription.associa_copie_multiple(r.library_names,r.numero_copie) : ''
      res << content_tag(:tr, content_tag(:td, cnt+=1) +
                              content_tag(:td, title) +
                              content_tag(:td, libraries))
    end
    content_tag(:table, res.join("\n").html_safe, {class: 'table table-bordered table-condensed table-striped'})
  end

  def serial_titles_list(records)
    res=[]; cnt=0

    records.each do |r|
      lnk = r.tot_copie=='0' ? link_to('Elimina', r, method: :delete, data: { confirm: 'Confermi cancellazione titolo?' }) : ''
      note = r.note.blank? ? '' : "<br/>Nota interna: <em>#{r.note}</em>"
      note_fornitore = r.note_fornitore.blank? ? '' : "<br/>Nota fornitore: <em>#{r.note_fornitore}</em>"
      freq = r.frequency_label.blank? ? '' : " [<em>#{r.frequency_label}</em>]"
      publisher = r.publisher.blank? ? '' : ". - #{r.publisher}"
      # title=link_current_params("#{r.title}#{freq}#{publisher}#{note}#{note_fornitore}".html_safe, edit_serial_title_path(r), params)
      clavis_lnk= r.manifestation_id.nil? ? '' : link_to("Clavis", ClavisManifestation.clavis_url(r.manifestation_id), {class:'btn btn-success',target:'_new'})
      title=link_current_params("#{r.title}#{freq}#{publisher}".html_safe, edit_serial_title_path(r), params) +
            clavis_lnk + content_tag(:span, "#{note}#{note_fornitore}".html_safe)

      if r.tot_copie.to_i > 1
        totale = "#{r.prezzo_totale_stimato} (#{r.tot_copie}&nbsp;copie)".html_safe
      else
        totale = ''
      end
      libraries=SerialSubscription.associa_copie_multiple(r.library_names,r.numero_copie)
      lnklib=link_current_params(libraries, serial_title_path(r), params)
      if !params[:library_id].blank? and !r.manifestation_id.nil? and params[:items_details]=='t'
        title << serial_titles_issues_report(r)
      end
      # invoice_link = r.invoice_ids.blank? ? '' : "<br/>#{edit_serial_invoice_path(r.invoice_ids,serial_list_id:r.serial_list_id,library_id:@library_id,invoice_filter_enabled:true)}"

      invoice_link = r.invoice_ids.blank? ? '' : %Q{<br/>#{link_to("<b>fattura</b>".html_safe, edit_serial_invoice_path(r.invoice_ids.to_i,serial_list_id:r.serial_list_id,library_id:r.libraries.to_i,invoice_filter_enabled:true))}}
      sspath = "/serial_subscriptions/#{r.id},#{r.libraries.to_i}"
      subscription_link = r.invoice_ids.blank? ? '' : %Q{ | #{link_to("<b>altro</b>".html_safe, sspath)}}

      res << content_tag(:tr, content_tag(:td, cnt+=1) +
                              content_tag(:td, title) +
                              content_tag(:td, r.prezzo_stimato) +
                              content_tag(:td, totale) +
                              content_tag(:td, lnklib + invoice_link.html_safe + subscription_link.html_safe) +
                              content_tag(:td, lnk))
    end
    content_tag(:table, res.join.html_safe, {class: 'table table-bordered table-condensed table-striped'})
  end

  def serial_titles_invoice_select(records, serial_invoice, library_id)
    res=[]; cnt=0
    prst=pr=0
    records.each do |r|
      freq = r.frequency_label.blank? ? '' : " [<em>#{r.frequency_label}</em>]"
      mytit = "#{r.title}#{freq}"

      price = r.invoice_ids.blank? ? '' : invoice_editable(r, serial_invoice.id, library_id)
      prst += r.prezzo_stimato if !r.prezzo_stimato.nil?
      # pr += r.prezzo_in_fattura
      checkbox=check_box_tag("titles_invoice[#{r.id}]", 't', (r.invoice_ids.blank? ? false : true), :onchange=>'')
      label = label_tag("titles_invoice[#{r.id}]", r.title)
      res << content_tag(:tr, content_tag(:td, checkbox) +
                              content_tag(:td, label) +
                              content_tag(:td,r.prezzo_stimato) +
                              content_tag(:td, price))
      res << hidden_field_tag("titles[#{r.id}]", true)
    end
    res << content_tag(:tr, content_tag(:td, '') +
                            content_tag(:td, '') +
                            content_tag(:td,prst) +
                            content_tag(:td,'-'))
    content_tag(:table, res.join("\n").html_safe, {class: 'table table-bordered table-condensed table-striped'})
  end

  def serial_titles_invoice_list(serial_invoice)
    res=[]; cnt=0
    prst=pr=0
    records = serial_invoice.subscriptions
    records.each do |r|
      lnk_library_name = serial_subscription_path(r.serial_title_id,{ok_library_id:r.library_id})

      res << content_tag(:tr, content_tag(:td, r.title) +
                              content_tag(:td, link_to(r.library_name,lnk_library_name)) +
                              content_tag(:td, r.prezzo_in_fattura) +
                              content_tag(:td, r.prezzo_stimato))
    end
    content_tag(:table, res.join("\n").html_safe, {class: 'table table-bordered table-condensed table-striped'})
  end

  def serial_libraries_list(records)
    res=[]; cnt=0
    records.each do |r|
      if can? :manage, SerialList
        lnk = @serial_list.locked? ? '' : link_to('Elimina', delete_library_serial_list_path(@serial_list, library_id:r.library_id), method: :delete, data: { confirm: "Confermi cancellazione della biblioteca #{r.label} e di tutti i titoli e gli abbonamenti a essa collegata?" })
      else
        lnk = ''
      end
      lnk = '-'
      res << content_tag(:tr, content_tag(:td, r.sigla) +
                              content_tag(:td, r.nickname) +
                              content_tag(:td, r.label) +
                              content_tag(:td, lnk))
    end
    content_tag(:table, res.join.html_safe, {class: 'table table-bordered table-condensed table-striped'})
  end
  
  def periodico_show(record)
    res=[]
    record.attributes.keys.each do |k|
      next if record[k].blank?
      res << content_tag(:tr, content_tag(:td, k, class:'col-sm-2') + content_tag(:td, record[k]))
    end
    res=content_tag(:table, res.join.html_safe, {class: 'table table-striped'})
  end

  def periodici_import_list_files(sourcedir)
    files = []
    Dir[File.join(sourcedir,'*.txt')].sort.each do |entry|
      fname=File.basename(entry)
      files << link_to(fname, import_serial_list_path(sourcefile:fname))
    end
    content_tag(:pre, files.join("\n").html_safe)
  end

  def periodici_breadcrumbs
    # return params.inspect
    links=[]

    # links << link_to('Liste periodici', serial_lists_path) if params[:controller]!='lperiodici'
    links << link_to('Liste periodici', serial_lists_path)

    if ['serial_titles','serial_invoices','serial_subscriptions'].include?(params[:controller]) and ['new','create','edit','update','show','print'].include?(params[:action])
      params[:serial_list_id]=@serial_list.id if params[:serial_list_id].blank?
      links << link_current_params(@serial_list.to_label, serial_titles_path,params)
    end

    if ['serial_titles','serial_subscriptions'].include?(params[:controller]) and params[:action] = 'show' and !params[:id].blank?
      links << link_current_params(content_tag(:b, @serial_title.title), serial_title_path,params)
    end

    if params[:action]=='index' and !@serial_list.nil?
      links << link_current_params(@serial_list.to_label, serial_titles_path,params)
    end

    if params[:controller]=='serial_invoices' and params[:action]=='show'
      links << link_current_params("Fatture", serial_invoices_path, params)
    end


    return '' if links.size==0
 
    %Q{&nbsp; / &nbsp;#{links.join('&nbsp; / &nbsp;')}}.html_safe
  end

  def serial_titles_issues_report(r)
    res=[]
    cmds=[
      :issue_descriptions,
      :issue_status,
      :issue_arrival_dates,
      :issue_arrival_dates_expected,
    ]

    cmds.each do |cmd|
      dat=r.send(cmd)
      dat.gsub!(/{|}/,'')
      ar=CSV.parse_line(dat)
      item_ids=CSV.parse_line(r.send(:item_ids).gsub(/{|}/,'')) if cmd==:issue_descriptions
      td=[]
      i=0
      # td << content_tag(:td, cmd[6..-1].capitalize)
      while i < ar.size  do
        if cmd==:issue_descriptions
          td << content_tag(:td, link_to(ar[i], ClavisItem.clavis_url(item_ids[i]), :target=>'_new'))
        else
          td << content_tag(:td, ar[i])
        end
        i+=1
      end
      res << content_tag(:tr, td.join.html_safe, {title:cmd[6..-1].capitalize})
    end
    content_tag(:table, res.join.html_safe, {:style=>'width: 90%;', class: 'table table-bordered table-condensed table-striped'})
  end

  def invoice_editable(serial_title, invoice_id, library_id)
    @serial_subscription=SerialSubscription.find(serial_title.id,library_id)
    best_in_place(@serial_subscription, :prezzo, ok_button:'Salva', cancel_button:'Annulla',
                  ok_button_class:'btn btn-success',
                  class:'btn btn-default',
                       skip_blur:false,
                       :place_holder => "Prezzo in fattura qui",
                  html_attrs:{size:10})
  end

  def serial_invoices_shortlist(records)
    res = []
    records.each do |r|
      res << content_tag(:tr, content_tag(:td, link_to(r.to_label, serial_invoice_path(r))) +
                              content_tag(:td, r.total_amount)
                        )
    end
    content_tag(:table, res.join.html_safe, class:'table table-striped')
   end
  
  def serial_invoices_list(serial_list)
    return "serial_list #{serial_list.id} non gestisce le fatture" if serial_list.invoice_management==false
    res = []
    if serial_list.serial_invoices_report.size == 1
      serial_list.serial_invoices.each do |r|
        res << content_tag(:tr, content_tag(:td, r.clavis_invoice.to_label))
      end
    else
      rr=nil
      res << content_tag(:tr, content_tag(:td, '') +
                              content_tag(:td, 'ID Clavis') +
                              content_tag(:td, 'Numero fattura') +
                              content_tag(:td, 'Data fattura') +
                              content_tag(:td, 'Totale fattura') +
                              content_tag(:td, 'Importo fatturato') +
                              content_tag(:td, 'Prezzo stimato') +
                              content_tag(:td, 'Differenza'))

      cnt=0
      serial_list.serial_invoices_report.each do |r|
        cnt+=1
        rr = r and break if r.clavis_invoice_id.nil?
        prezzo = r.total_amount.to_f == r.prezzo.to_f ? number_to_currency(r.prezzo) : "<b>#{number_to_currency(r.prezzo)}</b>"
        diff = r.prezzo_stimato.to_f - r.prezzo.to_f
        res << content_tag(:tr, content_tag(:td, cnt) +
                                content_tag(:td, link_to(r.id,r.clavis_url,target:'_blank',title:'Vedi questa fattura in Clavis')) +
                                content_tag(:td, link_to(r.invoice_number,serial_invoice_path(r,serial_list_id:r.serial_list_id,library_id:@library_id,invoice_filter_enabled:true))) +
                                content_tag(:td, r.invoice_date.to_date) +
                                content_tag(:td, number_to_currency(r.total_amount)) +
                                content_tag(:td, prezzo.html_safe) +
                                content_tag(:td, number_to_currency(r.prezzo_stimato)) +
                                content_tag(:td, number_to_currency(diff)))
      end
      prezzo = rr.total_amount.to_f == rr.prezzo.to_f ? number_to_currency(rr.prezzo) : "<b>#{number_to_currency(rr.prezzo)}</b>"
      res << content_tag(:tr, content_tag(:td, '', {colspan:4}) +
                              content_tag(:td, number_to_currency(rr.total_amount)) +
                              content_tag(:td, prezzo.html_safe) +
                              content_tag(:td, number_to_currency(rr.prezzo_stimato)) +
                              content_tag(:td, number_to_currency(rr.prezzo_stimato.to_f - rr.prezzo.to_f)))
    end

    content_tag(:table, res.join("\n").html_safe, {:style=>'width: 90%;', class: 'table table-bordered table-condensed table-striped'})
  end
end
