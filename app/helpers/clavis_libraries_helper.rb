module ClavisLibrariesHelper
  def clavis_libraries_celdes_libraries
    sql=%Q{SELECT cl.label,library_id FROM public.biblioteche_celdes bc JOIN clavis.library cl using(library_id) ORDER BY cl.label;}
    res = []
    year=Time.now.year
    ClavisLibrary.connection.execute(sql).each do |r|
      res << content_tag(:tr, content_tag(:td, link_to(r['label'], "periodici_ordini?library_id=#{r['library_id']}&year=#{year}")))
    end
    content_tag(:table, res.join.html_safe, {class: 'table table-striped'})
  end
end
