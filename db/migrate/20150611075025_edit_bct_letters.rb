class EditBctLetters < ActiveRecord::Migration
  def up
    add_column 'letterebct.letters', :descrizione_fisica, :string, :limit=>128
    add_column 'letterebct.letters', :updated_by, :integer
    add_column 'letterebct.letters', :updated_at, :datetime
  end

  def down
    remove_column 'letterebct.letters', :descrizione_fisica
    remove_column 'letterebct.letters', :updated_by
    remove_column 'letterebct.letters', :updated_at
  end
end
