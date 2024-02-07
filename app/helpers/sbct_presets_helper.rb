# coding: utf-8
module SbctPresetsHelper

  def sbct_presets_index(sbct_presets)
    res = []
    res << content_tag(:tr, content_tag(:td, 'Nome', class:'col-md-4 text-left') +
                            content_tag(:td, 'Descrizione', class:'col-md-6 text-left') +
                            content_tag(:td, '', class:'col-md-1') +
                            content_tag(:td, '', class:'col-md-1'), class:'success')
                            

    sbct_presets.each do |r|
      elimina = ''
      elimina = link_to("Elimina", r, method: :delete, data: { confirm: "Confermi eliminazione della scorciatoia #{r.label}?" }, class:'btn btn-warning') if can? :destroy, SbctPreset
      modifica = ''
      modifica = link_to('Modifica', edit_sbct_preset_path(r), class:'btn btn-success') if can? :edit, SbctPreset
      res << content_tag(:tr, content_tag(:td, sbct_presets_link_to(r)) +
                              content_tag(:td, r.description) +
                              content_tag(:td, modifica) +
                              content_tag(:td, elimina))
    end
    content_tag(:table, res.join.html_safe, class:'table table-condensed')

  end

  def sbct_presets_link_to(preset)
    link_to(preset.label, preset.path, class:'btn btn-success')
  end

end
