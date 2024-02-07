class SbctLBudgetLibrary < ActiveRecord::Base
  self.table_name = 'sbct_acquisti.l_budgets_libraries'
  self.primary_keys = [:budget_id, :clavis_library_id]

  attr_accessible :quota, :budget_id, :clavis_library_id

  belongs_to :sbct_budget, :foreign_key=>'budget_id'
  belongs_to :clavis_library, :foreign_key=>'clavis_library_id'


  def SbctLBudgetLibrary.label_select(budget_id)
    sql = %Q{
    select lc.label || ' - ' || cl.shortlabel as name,lc.clavis_library_id as key
     from sbct_acquisti.library_codes lc 
       join clavis.library cl on(cl.library_id=lc.clavis_library_id) left join public.pac_budgets pb
        on(pb.library_id=lc.clavis_library_id and pb.budget_id=#{budget_id.to_i})
       where pb.budget_id is null and cl.library_internal='1' and cl.library_status='A'
         order by lc.label;}
    
    res = []
    self.connection.execute(sql).to_a.each do |r|
      label = r['name']
      res << [label,r['key']]
    end
    res
  end


  
end

