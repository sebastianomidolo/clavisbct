# coding: utf-8
class SbctPreset < ActiveRecord::Base
  self.table_name='sbct_acquisti.presets'
  attr_accessible :description, :label, :path

end
