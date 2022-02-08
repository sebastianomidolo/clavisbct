# -*- encoding: utf-8 -*-
# stub: sass-rails 3.2.6 ruby lib

Gem::Specification.new do |s|
  s.name = "sass-rails".freeze
  s.version = "3.2.6"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["wycats".freeze, "chriseppstein".freeze]
  s.date = "2013-01-14"
  s.description = "Sass adapter for the Rails asset pipeline.".freeze
  s.email = ["wycats@gmail.com".freeze, "chris@eppsteins.net".freeze]
  s.homepage = "".freeze
  s.rubyforge_project = "sass-rails".freeze
  s.rubygems_version = "2.5.2.3".freeze
  s.summary = "Sass adapter for the Rails asset pipeline.".freeze

  s.installed_by_version = "2.5.2.3" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<sass>.freeze, [">= 3.1.10"])
      s.add_runtime_dependency(%q<railties>.freeze, ["~> 3.2.0"])
      s.add_runtime_dependency(%q<tilt>.freeze, ["~> 1.3"])
    else
      s.add_dependency(%q<sass>.freeze, [">= 3.1.10"])
      s.add_dependency(%q<railties>.freeze, ["~> 3.2.0"])
      s.add_dependency(%q<tilt>.freeze, ["~> 1.3"])
    end
  else
    s.add_dependency(%q<sass>.freeze, [">= 3.1.10"])
    s.add_dependency(%q<railties>.freeze, ["~> 3.2.0"])
    s.add_dependency(%q<tilt>.freeze, ["~> 1.3"])
  end
end
