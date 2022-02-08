# -*- encoding: utf-8 -*-
# stub: responders 1.1.2 ruby lib

Gem::Specification.new do |s|
  s.name = "responders".freeze
  s.version = "1.1.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Jos\u{e9} Valim".freeze]
  s.date = "2014-11-07"
  s.description = "A set of Rails responders to dry up your application".freeze
  s.email = "contact@plataformatec.com.br".freeze
  s.homepage = "http://github.com/plataformatec/responders".freeze
  s.licenses = ["MIT".freeze]
  s.rubyforge_project = "responders".freeze
  s.rubygems_version = "2.5.2.3".freeze
  s.summary = "A set of Rails responders to dry up your application".freeze

  s.installed_by_version = "2.5.2.3" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<railties>.freeze, ["< 4.2", ">= 3.2"])
    else
      s.add_dependency(%q<railties>.freeze, ["< 4.2", ">= 3.2"])
    end
  else
    s.add_dependency(%q<railties>.freeze, ["< 4.2", ">= 3.2"])
  end
end
