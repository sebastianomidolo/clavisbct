require 'simplecov'
# require deps
require 'tmpdir'
require 'fileutils'
require 'minitest/autorun'
require 'shoulda'
require 'fileutils'
require 'timeout'
require 'logger'
require 'date'
require 'webmock/minitest'

# require gem files
require File.dirname(__FILE__) + '/../lib/roo-xls'

TESTDIR =  File.join(File.dirname(__FILE__), 'files')

ONLINE = false
LONG_RUN = false

# very simple diff implementation
# output is an empty string if the files are equal
# otherwise differences a printen (not compatible to
# the diff command)
def file_diff(fn1, fn2)
  result = ''
  File.open(fn1) do |f1|
    File.open(fn2) do |f2|
      while f1.eof? == false && f2.eof? == false
        line1 = f1.gets.chomp
        line2 = f2.gets.chomp
        result << "<#{line1}\n>#{line2}\n" if line1 != line2
      end
      if f1.eof? == false
        while f1.eof? == false
          line1 = f1.gets
          result << "<#{line1}\n"
        end
      end
      if f2.eof? == false
        while f2.eof? == false
          line2 = f2.gets
          result << ">#{line2}\n"
        end
      end
    end
  end
  result
end

class File
  def self.delete_if_exist(filename)
    if File.exist?(filename)
      File.delete(filename)
    end
  end
end
