# -*- coding: utf-8 -*-
class BioIconograficoNamespaceUser < ActiveRecord::Base
  self.table_name='public.bio_icon_namespaces_users'
  self.primary_keys = [:label,:user_id]

  belongs_to :bio_iconografico_namespace, :foreign_key=>'label', :primary_key=>'label'
  belongs_to :user, :foreign_key=>'user_id', :primary_key=>'id'

end
