# -*- encoding: utf-8 -*-
# stub: composite_primary_keys 5.0.14 ruby lib

Gem::Specification.new do |s|
  s.name = "composite_primary_keys".freeze
  s.version = "5.0.14"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Dr Nic Williams".freeze, "Charlie Savage".freeze]
  s.date = "2014-03-16"
  s.description = "Composite key support for ActiveRecord".freeze
  s.homepage = "https://github.com/drnic/composite_primary_keys".freeze
  s.required_ruby_version = Gem::Requirement.new(">= 1.8.7".freeze)
  s.rubyforge_project = "compositekeys".freeze
  s.rubygems_version = "2.5.2.3".freeze
  s.summary = "Composite key support for ActiveRecord".freeze

  s.installed_by_version = "2.5.2.3" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<activerecord>.freeze, [">= 3.2.9", "~> 3.2.0"])
    else
      s.add_dependency(%q<activerecord>.freeze, [">= 3.2.9", "~> 3.2.0"])
    end
  else
    s.add_dependency(%q<activerecord>.freeze, [">= 3.2.9", "~> 3.2.0"])
  end
end
