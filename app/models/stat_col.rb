class StatCol < ActiveRecord::Base
  self.table_name='stats.statcols'
  attr_accessible :statcol, :description

  def StatCol.stacols_select
    
    sql=%Q{select statcol from #{self.table_name} order by statcol}
    self.connection.execute(sql).collect {|i| [i['statcol'],i['statcol']]}


    
  end

end
