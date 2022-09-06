class SbctTipoTitolo < ActiveRecord::Base

  self.table_name='sbct_acquisti.tipi_titolo'

  def to_label
    self.tipo_titolo
  end

  def SbctTipoTitolo.options_for_select
    SbctTipoTitolo.order('id_tipo_titolo').collect {|x| ["#{x.id_tipo_titolo} - #{x.tipo_titolo}",x.id_tipo_titolo]}
  end

end
