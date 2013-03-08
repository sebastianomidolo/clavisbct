class ProculturaArchive < ActiveRecord::Base
  self.table_name = 'procultura.archives'
  has_many :folders, :class_name=>'ProculturaFolder', :foreign_key=>'archive_id', :order=>'lower(label)'

  def self.list
    sql=%Q{select a.id,a.name,count(*) from procultura.archives a
      join procultura.folders f on(f.archive_id=a.id) join procultura.cards c
        on(c.folder_id=f.id) group by a.id,a.name,a.name order by a.name;}
    self.connection.execute(sql).to_a
  end

end
