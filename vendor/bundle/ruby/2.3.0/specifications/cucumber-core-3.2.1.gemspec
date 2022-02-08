# -*- encoding: utf-8 -*-
# stub: cucumber-core 3.2.1 ruby lib

Gem::Specification.new do |s|
  s.name = "cucumber-core".freeze
  s.version = "3.2.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Aslak Helles\u{f8}y".freeze, "Matt Wynne".freeze, "Steve Tooke".freeze, "Oleg Sukhodolsky".freeze, "Tom Brand".freeze]
  s.date = "2018-09-24"
  s.description = "Core library for the Cucumber BDD app".freeze
  s.email = "cukes@googlegroups.com".freeze
  s.homepage = "https://cucumber.io".freeze
  s.licenses = ["MIT".freeze]
  s.rdoc_options = ["--charset=UTF-8".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.1".freeze)
  s.rubygems_version = "2.5.2.3".freeze
  s.summary = "cucumber-core-3.2.1".freeze

  s.installed_by_version = "2.5.2.3" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<gherkin>.freeze, ["~> 5.0"])
      s.add_runtime_dependency(%q<cucumber-tag_expressions>.freeze, ["~> 1.1.0"])
      s.add_runtime_dependency(%q<backports>.freeze, [">= 3.8.0"])
      s.add_development_dependency(%q<bundler>.freeze, ["~> 1.16.0"])
      s.add_development_dependency(%q<rake>.freeze, [">= 0.9.2"])
      s.add_development_dependency(%q<rspec>.freeze, ["~> 3.6"])
      s.add_development_dependency(%q<unindent>.freeze, [">= 1.0"])
      s.add_development_dependency(%q<kramdown>.freeze, ["~> 1.4.2"])
      s.add_development_dependency(%q<yard>.freeze, [">= 0"])
      s.add_development_dependency(%q<coveralls>.freeze, ["~> 0.7"])
    else
      s.add_dependency(%q<gherkin>.freeze, ["~> 5.0"])
      s.add_dependency(%q<cucumber-tag_expressions>.freeze, ["~> 1.1.0"])
      s.add_dependency(%q<backports>.freeze, [">= 3.8.0"])
      s.add_dependency(%q<bundler>.freeze, ["~> 1.16.0"])
      s.add_dependency(%q<rake>.freeze, [">= 0.9.2"])
      s.add_dependency(%q<rspec>.freeze, ["~> 3.6"])
      s.add_dependency(%q<unindent>.freeze, [">= 1.0"])
      s.add_dependency(%q<kramdown>.freeze, ["~> 1.4.2"])
      s.add_dependency(%q<yard>.freeze, [">= 0"])
      s.add_dependency(%q<coveralls>.freeze, ["~> 0.7"])
    end
  else
    s.add_dependency(%q<gherkin>.freeze, ["~> 5.0"])
    s.add_dependency(%q<cucumber-tag_expressions>.freeze, ["~> 1.1.0"])
    s.add_dependency(%q<backports>.freeze, [">= 3.8.0"])
    s.add_dependency(%q<bundler>.freeze, ["~> 1.16.0"])
    s.add_dependency(%q<rake>.freeze, [">= 0.9.2"])
    s.add_dependency(%q<rspec>.freeze, ["~> 3.6"])
    s.add_dependency(%q<unindent>.freeze, [">= 1.0"])
    s.add_dependency(%q<kramdown>.freeze, ["~> 1.4.2"])
    s.add_dependency(%q<yard>.freeze, [">= 0"])
    s.add_dependency(%q<coveralls>.freeze, ["~> 0.7"])
  end
end
