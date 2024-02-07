class SbctLBudgetSupplier < ActiveRecord::Base
  self.table_name = 'sbct_acquisti.l_budgets_suppliers'

  belongs_to :sbct_budget, :foreign_key=>'budget_id'
  belongs_to :sbct_supplier, :foreign_key=>'supplier_id'

end
