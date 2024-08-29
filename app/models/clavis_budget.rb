class ClavisBudget < ActiveRecord::Base
  self.table_name='clavis.budget'
  self.primary_key = 'budget_id'

  belongs_to :clavis_library, foreign_key:'library_id'

  def ClavisBudget.clavis_url(id)
    config = Rails.configuration.database_configuration
    host=config[Rails.env]['clavis_host']
    "#{host}/index.php?page=Acquisition.BudgetViewPage&id=#{id}"
  end

  def ClavisBudget.label_select
    sql = %Q{select cs.budget_id as key,cs.budget_title as label, cs.total_amount, cs.library_id, lc.label
      from clavis.budget cs left join sbct_acquisti.budgets s on(s.clavis_budget_id=cs.budget_id)
         join sbct_acquisti.library_codes lc on(lc.clavis_library_id=cs.library_id)
          where s is null and cs.end_validity > now() order by cs.budget_title;}
    puts sql
    res = []
    self.connection.execute(sql).to_a.each do |r|
      label = "#{r['label']} (#{r['total_amount']} euro - biblioteca #{r['label']} - #{r['library_id']})"
      res << [label,r['key']]
    end
    res
  end

end
