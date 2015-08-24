
# a mano:
# update procultura.cards set sort_text = lower(heading) where sort_text is null;

class AlterProculturaCards < ActiveRecord::Migration
  def up
    add_column 'procultura.cards', :sort_text, :string, :limit=>240
  end

  def down
    remove_column 'procultura.cards', :sort_text
  end
end
