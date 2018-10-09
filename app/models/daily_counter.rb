class DailyCounter < ActiveRecord::Base

  def DailyCounter.reset
    sql=%Q{TRUNCATE daily_counters;SELECT setval('daily_counters_id_seq', 1)}
    self.connection.execute sql
  end


end
