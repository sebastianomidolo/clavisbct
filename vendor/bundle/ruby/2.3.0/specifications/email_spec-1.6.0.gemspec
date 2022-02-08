# -*- encoding: utf-8 -*-
# stub: email_spec 1.6.0 ruby lib

Gem::Specification.new do |s|
  s.name = "email_spec".freeze
  s.version = "1.6.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Ben Mabey".freeze, "Aaron Gibralter".freeze, "Mischa Fierer".freeze]
  s.date = "2014-05-27"
  s.description = "Easily test email in RSpec, Cucumber, and MiniTest".freeze
  s.email = "ben@benmabey.com".freeze
  s.extra_rdoc_files = ["README.md".freeze, "MIT-LICENSE.txt".freeze]
  s.files = ["MIT-LICENSE.txt".freeze, "README.md".freeze]
  s.homepage = "http://github.com/bmabey/email-spec/".freeze
  s.licenses = ["MIT".freeze]
  s.rubyforge_project = "email-spec".freeze
  s.rubygems_version = "2.5.2.3".freeze
  s.summary = "Easily test email in rspec and cucumber and minitest".freeze

  s.installed_by_version = "2.5.2.3" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<launchy>.freeze, ["~> 2.1"])
      s.add_runtime_dependency(%q<mail>.freeze, ["~> 2.2"])
      s.add_development_dependency(%q<rake>.freeze, [">= 0.8.7"])
      s.add_development_dependency(%q<cucumber>.freeze, [">= 0"])
      s.add_development_dependency(%q<cucumber-rails>.freeze, [">= 0"])
      s.add_development_dependency(%q<cucumber-sinatra>.freeze, [">= 0"])
      s.add_development_dependency(%q<rspec-rails>.freeze, [">= 2.14.0"])
      s.add_development_dependency(%q<delayed_job>.freeze, ["~> 2.0"])
      s.add_development_dependency(%q<pony>.freeze, [">= 0"])
      s.add_development_dependency(%q<sinatra>.freeze, [">= 0"])
      s.add_development_dependency(%q<rack-test>.freeze, [">= 0"])
      s.add_development_dependency(%q<rails>.freeze, ["= 3.0.7"])
      s.add_development_dependency(%q<sqlite3>.freeze, [">= 0"])
      s.add_development_dependency(%q<capybara>.freeze, [">= 0"])
      s.add_development_dependency(%q<database_cleaner>.freeze, [">= 0"])
      s.add_development_dependency(%q<test-unit>.freeze, [">= 0"])
    else
      s.add_dependency(%q<launchy>.freeze, ["~> 2.1"])
      s.add_dependency(%q<mail>.freeze, ["~> 2.2"])
      s.add_dependency(%q<rake>.freeze, [">= 0.8.7"])
      s.add_dependency(%q<cucumber>.freeze, [">= 0"])
      s.add_dependency(%q<cucumber-rails>.freeze, [">= 0"])
      s.add_dependency(%q<cucumber-sinatra>.freeze, [">= 0"])
      s.add_dependency(%q<rspec-rails>.freeze, [">= 2.14.0"])
      s.add_dependency(%q<delayed_job>.freeze, ["~> 2.0"])
      s.add_dependency(%q<pony>.freeze, [">= 0"])
      s.add_dependency(%q<sinatra>.freeze, [">= 0"])
      s.add_dependency(%q<rack-test>.freeze, [">= 0"])
      s.add_dependency(%q<rails>.freeze, ["= 3.0.7"])
      s.add_dependency(%q<sqlite3>.freeze, [">= 0"])
      s.add_dependency(%q<capybara>.freeze, [">= 0"])
      s.add_dependency(%q<database_cleaner>.freeze, [">= 0"])
      s.add_dependency(%q<test-unit>.freeze, [">= 0"])
    end
  else
    s.add_dependency(%q<launchy>.freeze, ["~> 2.1"])
    s.add_dependency(%q<mail>.freeze, ["~> 2.2"])
    s.add_dependency(%q<rake>.freeze, [">= 0.8.7"])
    s.add_dependency(%q<cucumber>.freeze, [">= 0"])
    s.add_dependency(%q<cucumber-rails>.freeze, [">= 0"])
    s.add_dependency(%q<cucumber-sinatra>.freeze, [">= 0"])
    s.add_dependency(%q<rspec-rails>.freeze, [">= 2.14.0"])
    s.add_dependency(%q<delayed_job>.freeze, ["~> 2.0"])
    s.add_dependency(%q<pony>.freeze, [">= 0"])
    s.add_dependency(%q<sinatra>.freeze, [">= 0"])
    s.add_dependency(%q<rack-test>.freeze, [">= 0"])
    s.add_dependency(%q<rails>.freeze, ["= 3.0.7"])
    s.add_dependency(%q<sqlite3>.freeze, [">= 0"])
    s.add_dependency(%q<capybara>.freeze, [">= 0"])
    s.add_dependency(%q<database_cleaner>.freeze, [">= 0"])
    s.add_dependency(%q<test-unit>.freeze, [">= 0"])
  end
end
