# -*- encoding: utf-8 -*-
# stub: ruby-mp3info 0.8.10 ruby lib

Gem::Specification.new do |s|
  s.name = "ruby-mp3info".freeze
  s.version = "0.8.10"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Guillaume Pierronnet".freeze]
  s.date = "2016-10-31"
  s.description = "ruby-mp3info read low-level informations and manipulate tags on mp3 files.".freeze
  s.email = ["guillaume.pierronnet@gmail.com".freeze]
  s.extra_rdoc_files = ["History.txt".freeze, "Manifest.txt".freeze, "README.md".freeze]
  s.files = ["History.txt".freeze, "Manifest.txt".freeze, "README.md".freeze]
  s.homepage = "http://github.com/moumar/ruby-mp3info".freeze
  s.licenses = ["MIT".freeze]
  s.rdoc_options = ["--main".freeze, "README.md".freeze]
  s.rubygems_version = "2.5.2.3".freeze
  s.summary = "ruby-mp3info read low-level informations and manipulate tags on mp3 files.".freeze

  s.installed_by_version = "2.5.2.3" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<rdoc>.freeze, ["~> 4.0"])
      s.add_development_dependency(%q<hoe>.freeze, ["~> 3.15"])
    else
      s.add_dependency(%q<rdoc>.freeze, ["~> 4.0"])
      s.add_dependency(%q<hoe>.freeze, ["~> 3.15"])
    end
  else
    s.add_dependency(%q<rdoc>.freeze, ["~> 4.0"])
    s.add_dependency(%q<hoe>.freeze, ["~> 3.15"])
  end
end
