class CreateBioIconograficoTopics < ActiveRecord::Migration
  def change
    create_table :bio_iconografico_topics do |t|
      t.xml :tags
    end
  end
end
