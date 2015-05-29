# -*- coding: utf-8 -*-
module BctLettersHelper

  def bct_letters_link_persona(record,ruolo)
    person=record.send(ruolo)
    return '' if person.nil?
    docs=person.numero_lettere
    if docs>1
      link_to(person.denominazione, bct_letters_path(:person_id=>person.id), :title=>"#{docs} lettere")
    else
      person.denominazione
    end
  end

  def bct_letters_datazione(record)
    record.ladata.blank? ? record.data : record.ladata
  end

  def bct_letters_letter_link_to_pdf(letter)
    url="http://bctwww.comperio.it/lettereautografe/4.pdf"
    link_to('pdf',url,:target=>'_new')
  end

  def bct_letters_menu_orizzontale
    r=[]
    links=[
           ['ClavisBCT', '/'],
           ['Lettere', '/bct_letters'],
           ['Mittenti e destinatari', '/bct_people'],
          ]
    links.each do |v|
      t,l=v
      lnk=link_to(t,l)
      r << content_tag(:li, lnk)
    end
    content_tag(:ul, r.join.html_safe)
  end

  def fondo_mostra_elenco_fondi(fondo_corrente)
    r=[]
    fondi = BctFondo.elenco
    fondi.each do |f|
      if params[:controller]=='bct_people'
        link = link_to(f.to_label, bct_people_path(:fondo_id => f.id))
      else
        link = link_to(f.to_label, bct_letters_path(:fondo_id => f.id))
      end
      classe = fondo_corrente.nil? ? '' : fondo_corrente.id==f.id ? 'fondo_corrente' : ''
      r << content_tag(:li, link, :class=>classe)
    end
    r.join.html_safe
  end

  def bct_letters_person_info(person)
    content_tag(:div, bct_letters_info_lettere_inviate(person)) + content_tag(:hr) +
      content_tag(:div, bct_letters_info_lettere_ricevute(person))

  end

  def bct_letters_info_lettere_inviate(person)
    l = person.lettere_inviate.size
    return nil if l==0
    p = person.luoghi_invio.size
    if p==1
      @bct_letter=BctLetter.find_by_mittente_id(person)
      return "Una lettera scritta a #{person.luoghi_invio.first.denominazione} #{render(:partial=>'/bct_letters/show')}".html_safe
    else
      res = link_to("#{l} lettere", bct_letters_path(:mittente_id=>person.id)) + " scritte in #{p} luoghi:"
    end
    r=[]
    person.luoghi_invio.collect do |l|
      r << content_tag(:li, link_to(l.denominazione, bct_place_path(l, bct_person_id:person)))
    end
    "#{res}#{content_tag(:ol, r.join.html_safe)}".html_safe
  end

  def bct_letters_info_lettere_ricevute(person)
    l = person.lettere_ricevute.size
    return nil if l==0
    p = person.luoghi_ricezione.size
    if p==1
      @bct_letter=BctLetter.find_by_destinatario_id(person)
      return "Una lettera ricevuta a #{person.luoghi_ricezione.first.denominazione} #{render(:partial=>'/bct_letters/show')}".html_safe
    else
      res = link_to("#{l} lettere", bct_letters_path(:destinatario_id=>person.id)) + " ricevute in #{p} luoghi:"
    end
    r=[]
    person.luoghi_ricezione.collect do |l|
      r << content_tag(:li, link_to(l.denominazione, bct_place_path(l, bct_person_id:person)))
    end
    "#{res}#{content_tag(:ol, r.join.html_safe)}".html_safe
  end

  def bct_letters_from_place(place,person)
    r=[]
    place.letters_from.where(mittente_id:person.id).each do |l|
      txt = l.destinatario.nil? ? '' : ", destinatario #{link_to(l.destinatario.denominazione,bct_person_path(l.destinatario))}".html_safe
      r << content_tag(:li, link_to(l.ladata, bct_letter_path(l)) + txt)
    end
    return nil if r.size==0
    "#{r.size} lettere scritte a <b>#{place.denominazione}</b>:#{content_tag(:ol, r.join.html_safe)}".html_safe
  end
  def bct_letters_to_place(place,person)
    r=[]
    place.letters_to.where(destinatario_id:person.id).each do |l|
      txt = l.mittente.nil? ? '' : ", mittente #{link_to(l.mittente.denominazione,bct_person_path(l.mittente))}".html_safe
      r << content_tag(:li, link_to(l.ladata, bct_letter_path(l)) + txt)
    end
    return nil if r.size==0
    "#{r.size} lettere ricevute a <b>#{place.denominazione}</b>: #{content_tag(:ol, r.join.html_safe)}".html_safe
  end

end

                    
