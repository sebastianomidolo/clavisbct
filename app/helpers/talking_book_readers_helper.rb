# coding: utf-8
module TalkingBookReadersHelper
  def talking_book_readers_list(records)
    res = []
    res << content_tag(:tr, content_tag(:td, "<b>Nome e cognome</b>".html_safe, class:'col-md-4') +
                            content_tag(:td, "<b>Libri letti</b>".html_safe, class:'col-md-2') +
                            content_tag(:td, "<b>Attivo</b>".html_safe))
    records.each do |r|
      txt = "#{r.nome} #{r.cognome}"
      txt = '[modifica]' if txt.blank?
      lnk = link_to(txt, talking_book_reader_path(r))
      cssclass=r.attivo? ? 'success' : 'danger'
      lnk_catalogo = r.count=='0' ? '-' : link_to(r.count, talking_books_path(talking_book_reader_id:r.id),
                                                  class:'center-block',
                                                  title:"libri letti da #{r.to_label}")
      res << content_tag(:tr, content_tag(:td, lnk) +
                              content_tag(:td, lnk_catalogo) +
                              content_tag(:td, (r.attivo? ? 'Attivo' : 'Non attivo')), class:cssclass)
    end
    content_tag(:table, res.join.html_safe, class:'table')
  end

  def talking_book_reader_edit(form,record)
    res=[]
    fields={
      cognome: 'Cognome',
      nome: 'Nome',
      telefono: 'Telefono',
      attivo: ['Attivo', :boolean],
    }
    fields.keys.each do |k|
      label, as_value = fields[k]
      as_value = :string if as_value.blank?
      # res << content_tag(:p, "k=#{k} - label: #{label} - as_value: #{as_value}")
      if as_value == :date
        f=form.input k.to_sym, label:label, as: as_value, :include_blank => true
        res << content_tag(:p, f)
      else
        if k== :talking_book_reader_id
          f=form.association :talking_book_reader, collection:TalkingBookReader.order(:cognome), include_blank:true, label:label
        else
          input_html = as_value==:text ? {cols: 80, rows: 3} : {}
          f=form.input k.to_sym, label:label, as: as_value, input_html: input_html
        end
        res << content_tag(:pre, f)
      end
    end
    content_tag(:div, res.join.html_safe)
  end

  
end
