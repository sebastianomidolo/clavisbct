class ServiceDoc < ActiveRecord::Base
  attr_accessible :doc_text, :service_id, :service_doc_type_id, :title

  belongs_to :service
  belongs_to :service_doc_type
  has_many :attachments, :as => :attachable

  def to_label
    title = self.title.blank? ? 'senza titolo' : self.title
    "#{title} (#{self.service_doc_type_id})"
  end

  def ServiceDoc.tutti(service_doc,user)
    cond = []
    cond << "s.visible" if !user.role?('ServiceManager')
    cond << "sd.service_doc_type_id = '#{service_doc.service_doc_type.code}'" if !service_doc.service_doc_type.nil?
    cond << "s.id = #{service_doc.service.id}" if !service_doc.service.nil?
    cond = cond.size==0 ? '' : "WHERE #{cond.join(' and ')}"
    sql = %Q{select sd.*, s.name as service_name from service_docs sd 
     join services s on(s.id=sd.service_id)
     join service_doc_types dt on (dt.code=service_doc_type_id)
    #{cond} order by service_name,sd.title,dt.label}
    puts sql
    ServiceDoc.find_by_sql(sql)
  end

end
