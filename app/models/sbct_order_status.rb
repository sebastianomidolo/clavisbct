# coding: utf-8

class SbctOrderStatus < ActiveRecord::Base
  self.table_name='sbct_acquisti.order_status'

  has_many :sbct_items, foreign_key:'order_status'

  def to_label
    "#{self.id} - #{self.label}"
  end

  def SbctOrderStatus.options_for_select
      SbctOrderStatus.order('id').collect {|x| ["#{x.id} - #{x.label}",x.id]}
  end

end

