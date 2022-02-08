# HTTPI

A common interface for Ruby's HTTP libraries.

[Documentation](https://www.rubydoc.info/gems/httpi) |
[Mailing list](https://groups.google.com/forum/#!forum/httpirb)

[![Build Status](https://secure.travis-ci.org/savonrb/httpi.svg?branch=master)](http://travis-ci.org/savonrb/httpi)
[![Gem Version](https://badge.fury.io/rb/httpi.svg)](http://badge.fury.io/rb/httpi)
[![Code Climate](https://codeclimate.com/github/savonrb/httpi.svg)](https://codeclimate.com/github/savonrb/httpi)
[![Coverage Status](https://coveralls.io/repos/savonrb/httpi/badge.svg?branch=master)](https://coveralls.io/r/savonrb/httpi)


## Installation

HTTPI is available through [Rubygems](https://rubygems.org/gems/httpi) and can be installed via:

```
$ gem install httpi
```

or add it to your Gemfile like this:

```
gem 'httpi', '~> 2.1.0'
```


## Usage example


``` ruby
require "httpi"

# create a request object
request = HTTPI::Request.new
request.url = "http://example.com"

# and pass it to a request method
HTTPI.get(request)

# use a specific adapter per request
HTTPI.get(request, :curb)

# or specify a global adapter to use
HTTPI.adapter = :httpclient

# and execute arbitary requests
HTTPI.request(:custom, request)
```


## Documentation

Continue reading at https://www.rubydoc.info/gems/httpi
