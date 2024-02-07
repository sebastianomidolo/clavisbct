class SbctLTitleList < ActiveRecord::Base
  self.table_name = 'sbct_acquisti.l_titoli_liste'

  belongs_to :sbct_title, :foreign_key=>'id_titolo'
  belongs_to :sbct_list, :foreign_key=>'id_lista'

end

