# coding: utf-8

class DObjectsPersonalFolder < ActiveRecord::Base
  belongs_to :user

  def ids
    return [] if self.d_objects.nil?
    self.d_objects.split(',').collect{|i| i.to_i}
  end

  def ids=(input)
    if input.class==Array
      self.d_objects = input.join(',')
    else
      self.d_objects = input
    end
  end

  def elements
    return [] if self.ids.size==0
    sql = %Q{select o.*,f.name as folder_name from public.d_objects o join public.d_objects_folders f 
         on(f.id=o.d_objects_folder_id) where o.id in(#{self.ids.join(', ')}) 
       order by naturalsort(f.name),naturalsort(o.name);}
    puts sql
    DObject.find_by_sql(sql)
  end

end

