class ContainersAddField < ActiveRecord::Migration
  def up
    add_column 'containers', :prenotabile, :boolean
  end

  def down
    remove_column 'containers', :prenotabile
  end
end
