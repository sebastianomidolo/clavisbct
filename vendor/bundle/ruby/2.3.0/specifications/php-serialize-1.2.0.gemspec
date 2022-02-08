# -*- encoding: utf-8 -*-
# stub: php-serialize 1.2.0 ruby lib/

Gem::Specification.new do |s|
  s.name = "php-serialize".freeze
  s.version = "1.2.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib/".freeze]
  s.authors = ["Thomas Hurst".freeze]
  s.date = "2017-06-29"
  s.description = "\t\tThis module provides two methods: PHP.serialize() and PHP.unserialize(), both\n\t\tof which should be compatible with the similarly named functions in PHP.\n\n\t\tIt can also serialize and unserialize PHP sessions.\n".freeze
  s.email = "tom@hur.st".freeze
  s.homepage = "http://www.aagh.net/projects/ruby-php-serialize".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "2.5.2.3".freeze
  s.summary = "Ruby analogs to PHP's serialize() and unserialize() functions".freeze

  s.installed_by_version = "2.5.2.3" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<bundler>.freeze, ["~> 1.15"])
      s.add_development_dependency(%q<rake>.freeze, ["~> 10.0"])
    else
      s.add_dependency(%q<bundler>.freeze, ["~> 1.15"])
      s.add_dependency(%q<rake>.freeze, ["~> 10.0"])
    end
  else
    s.add_dependency(%q<bundler>.freeze, ["~> 1.15"])
    s.add_dependency(%q<rake>.freeze, ["~> 10.0"])
  end
end
