# -*- encoding: utf-8 -*-
# stub: marc 1.0.4 ruby lib

Gem::Specification.new do |s|
  s.name = "marc".freeze
  s.version = "1.0.4"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Kevin Clarke".freeze, "Bill Dueber".freeze, "William Groppe".freeze, "Jonathan Rochkind".freeze, "Ross Singer".freeze, "Ed Summers".freeze]
  s.autorequire = "marc".freeze
  s.date = "2019-06-28"
  s.email = "ehs@pobox.com".freeze
  s.homepage = "https://github.com/ruby-marc/ruby-marc/".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 1.8.6".freeze)
  s.rubygems_version = "2.5.2.3".freeze
  s.summary = "A ruby library for working with Machine Readable Cataloging".freeze

  s.installed_by_version = "2.5.2.3" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<scrub_rb>.freeze, ["< 2", ">= 1.0.1"])
      s.add_runtime_dependency(%q<unf>.freeze, [">= 0"])
    else
      s.add_dependency(%q<scrub_rb>.freeze, ["< 2", ">= 1.0.1"])
      s.add_dependency(%q<unf>.freeze, [">= 0"])
    end
  else
    s.add_dependency(%q<scrub_rb>.freeze, ["< 2", ">= 1.0.1"])
    s.add_dependency(%q<unf>.freeze, [">= 0"])
  end
end
