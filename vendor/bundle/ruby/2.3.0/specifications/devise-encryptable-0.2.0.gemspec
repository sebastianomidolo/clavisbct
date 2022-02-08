# -*- encoding: utf-8 -*-
# stub: devise-encryptable 0.2.0 ruby lib

Gem::Specification.new do |s|
  s.name = "devise-encryptable".freeze
  s.version = "0.2.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Carlos Antonio da Silva".freeze, "Jos\u{e9} Valim".freeze, "Rodrigo Flores".freeze]
  s.date = "2014-05-05"
  s.description = "Encryption solution for salted-encryptors on Devise".freeze
  s.email = "opensource@plataformatec.com.br".freeze
  s.homepage = "http://github.com/plataformatec/devise-encryptable".freeze
  s.licenses = ["Apache 2.0".freeze]
  s.rubygems_version = "2.5.2.3".freeze
  s.summary = "Encryption solution for salted-encryptors on Devise".freeze

  s.installed_by_version = "2.5.2.3" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<devise>.freeze, [">= 2.1.0"])
    else
      s.add_dependency(%q<devise>.freeze, [">= 2.1.0"])
    end
  else
    s.add_dependency(%q<devise>.freeze, [">= 2.1.0"])
  end
end
