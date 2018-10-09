# RAILS_ENV=development rake db:migrate VERSION=20180829081721; RAILS_ENV=development rake db:migrate

# Questa tabella contiene solo un campo segue
class CreateDailyCounters < ActiveRecord::Migration
  def change
    create_table :daily_counters do |t|
    end
  end
end
