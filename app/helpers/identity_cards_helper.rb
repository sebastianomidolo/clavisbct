# coding: utf-8

module IdentityCardsHelper

  def identity_card_edit(form,record)
    res=[]
    fields={
      name: 'Nome',
      lastname: 'Cognome',
      national_id: 'Codice Fiscale',
      email: 'Email',
      birth_date: ['Data di nascita', :date],
    }
    fields.keys.each do |k|
      label, as_value = fields[k]
      as_value = :string if as_value.blank?
      if as_value == :date
        f=form.input k.to_sym, label:label, as: as_value, :include_blank => true,
                     start_year: Date.today.year - 120, end_year: Date.today.year
        res << content_tag(:span, f)
      else
        input_html = as_value==:text ? {cols: 80, rows: 3} : {size: 20}
        f=form.input k.to_sym, label:label, as: as_value, input_html: input_html
        res << content_tag(:span, f)
      end
    end
    content_tag(:div, res.join("\n").html_safe)
  end

  def identity_card_show(record)
    record.inspect
  end

  def identity_cards_list(records)
    res = []
    res << content_tag(:tr, content_tag(:td, "<b>Cognome e nome</b>".html_safe, class:'col-md-4') +
                            content_tag(:td, "<b>Codice fiscale</b>".html_safe, class:'col-md-2') +
                            content_tag(:td, "<b>Data di nascita</b>".html_safe) +
                            content_tag(:td, "<b>Documento</b>".html_safe))
    
    records.each do |r|
      lnk = link_to("#{r.lastname} #{r.name}", identity_card_path(r))
      cssclass=r.doc_uploaded? ? 'success' : 'danger'
      res << content_tag(:tr, content_tag(:td, lnk) +
                              content_tag(:td, r.national_id) +
                              content_tag(:td, r.birth_date) +
                              content_tag(:td, identity_card_image(r,'80',true)), class:cssclass)
    end
    content_tag(:table, res.join.html_safe, class:'table')

  end

  def identity_card_image(record, size, logged_in)
    if logged_in
      image_tag(docview_identity_card_path(record, size:size))
    else
      image_tag(newuser_docview_identity_card_path(record, size:size))
    end
  end
  
end
