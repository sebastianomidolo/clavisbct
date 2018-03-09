class AlterSchemaCollocazioniCentrale < ActiveRecord::Migration
  def up
    add_column SchemaCollocazioniCentrale.table_name, :locked, :boolean, :default=>false
  end

  def down
    remove_column SchemaCollocazioniCentrale.table_name, :locked
  end
end
