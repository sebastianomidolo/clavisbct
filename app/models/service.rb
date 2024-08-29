class Service < ActiveRecord::Base
  attr_accessible :name, :description, :parent_id, :url, :role_ids, :visible
  before_save :check_record
  validates :name, presence: true
  belongs_to :parent, class_name:'Service'
  has_and_belongs_to_many :roles
  has_many :service_docs
  has_many :attachments, :as => :attachable

  def to_label
    self.name
  end

  def check_record
    self.attribute_names.each do |f|
      self.assign_attributes(f=>nil) if self.send(f).blank?
    end
    self.visible = false if self.visible.nil?
    self
  end

  def is_top?
    self.parent_id.nil? ? true : false
  end

  def descendants_index
    Service.find_by_sql(self.sql_for_descendants_index)
  end

  def sql_for_descendants_index
    cond = []
    cond << "s.root_id=#{self.id}"
    cond = cond.join(' and ')
    sql=%Q{select s.id,s.level,s.name,s.visible,count(d.id) as num_docs,
   array_to_string(array_agg(d.service_doc_type_id),',') as service_doc_types
    from public.view_services s
    left join public.service_docs d on (d.service_id=s.id)
        where #{cond} and s.id!=s.root_id
	group by s.id,s.level,s.name,s.visible,s.order_sequence order by s.order_sequence;}
    # puts sql
    sql
  end

  def descendants_ids
    self.descendants_index.collect {|i| i.id}
  end

  def Service.parent_select(current_service)
    cond = []
    cond << "id!=#{current_service.id}"
    ids = current_service.descendants_ids
    cond << "id not in (#{ids.join(',')})" if ids.size > 0
    cond = cond.join(' AND ')
    sql = "select name as label,id as key from public.services where #{cond} order by name"
    puts sql
    res = []
    self.connection.execute(sql).to_a.each do |r|
      res << [r['label'],r['key']]
    end
    res

  end
  
end
