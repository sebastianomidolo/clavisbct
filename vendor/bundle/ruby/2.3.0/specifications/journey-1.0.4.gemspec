# -*- encoding: utf-8 -*-
# stub: journey 1.0.4 ruby lib

Gem::Specification.new do |s|
  s.name = "journey".freeze
  s.version = "1.0.4"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Aaron Patterson".freeze]
  s.date = "2012-06-14"
  s.description = "Journey is a router.  It routes requests.".freeze
  s.email = ["aaron@tenderlovemaking.com".freeze]
  s.extra_rdoc_files = ["Manifest.txt".freeze, "CHANGELOG.rdoc".freeze, "README.rdoc".freeze]
  s.files = ["CHANGELOG.rdoc".freeze, "Manifest.txt".freeze, "README.rdoc".freeze]
  s.homepage = "http://github.com/rails/journey".freeze
  s.rdoc_options = ["--main".freeze, "README.rdoc".freeze]
  s.rubyforge_project = "journey".freeze
  s.rubygems_version = "2.5.2.3".freeze
  s.summary = "Journey is a router".freeze

  s.installed_by_version = "2.5.2.3" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<minitest>.freeze, ["~> 2.11"])
      s.add_development_dependency(%q<racc>.freeze, [">= 1.4.6"])
      s.add_development_dependency(%q<rdoc>.freeze, ["~> 3.11"])
      s.add_development_dependency(%q<json>.freeze, [">= 0"])
      s.add_development_dependency(%q<rdoc>.freeze, ["~> 3.10"])
      s.add_development_dependency(%q<hoe>.freeze, ["~> 2.13"])
    else
      s.add_dependency(%q<minitest>.freeze, ["~> 2.11"])
      s.add_dependency(%q<racc>.freeze, [">= 1.4.6"])
      s.add_dependency(%q<rdoc>.freeze, ["~> 3.11"])
      s.add_dependency(%q<json>.freeze, [">= 0"])
      s.add_dependency(%q<rdoc>.freeze, ["~> 3.10"])
      s.add_dependency(%q<hoe>.freeze, ["~> 2.13"])
    end
  else
    s.add_dependency(%q<minitest>.freeze, ["~> 2.11"])
    s.add_dependency(%q<racc>.freeze, [">= 1.4.6"])
    s.add_dependency(%q<rdoc>.freeze, ["~> 3.11"])
    s.add_dependency(%q<json>.freeze, [">= 0"])
    s.add_dependency(%q<rdoc>.freeze, ["~> 3.10"])
    s.add_dependency(%q<hoe>.freeze, ["~> 2.13"])
  end
end
