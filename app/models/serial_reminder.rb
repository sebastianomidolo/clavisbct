# coding: utf-8
class SerialReminder < ActiveRecord::Base
  attr_accessible :label, :serial_title_id, :description, :reminder_date, :created_by, :date_created
  belongs_to :serial_title
  before_save :check_record

  def check_record
    self.attribute_names.each do |f|
      self.assign_attributes(f=>nil) if self.send(f).blank?
    end
    self.date_created = Time.now if self.date_created.nil?
    self
  end

  def SerialReminder.reminders_send(serial_list,user)
    sql = %Q{with t1 as (#{self.sql_for_tutti(serial_list,user)})
        update serial_reminders as r set reminder_date=now() from t1
         where r.id=t1.id and r.reminder_date is null;}
    self.connection.execute(sql)
  end
  
  def SerialReminder.tutti(serial_list,user,params={})
    sql = self.sql_for_tutti(serial_list,user,params)
    SerialReminder.find_by_sql(sql)
  end
  
  def SerialReminder.sql_for_tutti(serial_list,user,params={})
    if serial_list.nil?
      %Q{select sr.*,st.title,st.serial_list_id from serial_reminders sr join serial_titles st on(st.id = sr.serial_title_id)}
    else
      cond = 'and sr.reminder_date IS NULL' if params[:filter]=='D'
      cond = 'and sr.reminder_date IS NOT NULL' if params[:filter]=='I'
      cond = '' if params[:filter]=='A'
      %Q{select sr.*,st.title,st.serial_list_id from serial_reminders sr join serial_titles st on(st.id = sr.serial_title_id)
        where st.serial_list_id = #{serial_list.id} #{cond}}
    end
  end

end

