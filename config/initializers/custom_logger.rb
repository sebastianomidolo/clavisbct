fname = '/tmp/trylog.log'
# BctLogger = Logger.new(File.open(fname, 'a'))
BctLogger = ActiveSupport::TaggedLogging.new(Logger.new(File.open(fname, 'a')))
@@bctlogger=BctLogger
BctLogger.info "#{Time.new} - started new logger in #{fname}"
