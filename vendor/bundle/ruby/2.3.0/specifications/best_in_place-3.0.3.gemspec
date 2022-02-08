# -*- encoding: utf-8 -*-
# stub: best_in_place 3.0.3 ruby lib

Gem::Specification.new do |s|
  s.name = "best_in_place".freeze
  s.version = "3.0.3"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Bernat Farrero".freeze]
  s.date = "2015-01-26"
  s.description = "  BestInPlace is a jQuery script and a Rails helper that provide the method best_in_place to display\n  any object field easily editable for the user by just clicking on it. It supports input data,\n  text data, boolean data and custom dropdown data. It works with RESTful controllers.\n".freeze
  s.email = ["bernat@itnig.net".freeze]
  s.homepage = "http://github.com/bernat/best_in_place".freeze
  s.rubygems_version = "2.5.2.3".freeze
  s.summary = "It makes any field in place editable by clicking on it, it works for inputs, textareas, select dropdowns and checkboxes".freeze

  s.installed_by_version = "2.5.2.3" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<actionpack>.freeze, [">= 3.2"])
      s.add_runtime_dependency(%q<railties>.freeze, [">= 3.2"])
    else
      s.add_dependency(%q<actionpack>.freeze, [">= 3.2"])
      s.add_dependency(%q<railties>.freeze, [">= 3.2"])
    end
  else
    s.add_dependency(%q<actionpack>.freeze, [">= 3.2"])
    s.add_dependency(%q<railties>.freeze, [">= 3.2"])
  end
end
