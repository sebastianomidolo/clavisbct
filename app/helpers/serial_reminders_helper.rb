# coding: utf-8
module SerialRemindersHelper

  def serial_reminders_list(records)
    res = []
    res << content_tag(:tr, content_tag(:td, 'Titolo', class:'col-md-2 text-left') +
                            content_tag(:td, 'Label', class:'col-md-2 text-left') +
                            content_tag(:td, 'Descr', class:'col-md-4 text-left') +
                            content_tag(:td, 'DataPrep', class:'col-md-2 text-left') +
                            content_tag(:td, 'DataInvio', class:'col-md-1 text-left') +
                            content_tag(:td, '', class:'col-md-2'), class:'success')

    records.each do |r|
      reminder_date = r.reminder_date.nil? ? '' : r.reminder_date.to_date
      res << content_tag(:tr, content_tag(:td, link_to(r.title,serial_reminder_path(r.id))) +
                              content_tag(:td, r.label) +
                              content_tag(:td, r.description) +
                              content_tag(:td, r.date_created.to_date) +
                              content_tag(:td, reminder_date) 
                        )
    end
    content_tag(:table, res.join.html_safe, class:'table table-condensed')
  end

end
