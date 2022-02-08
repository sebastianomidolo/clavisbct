# -*- encoding: utf-8 -*-
# stub: ruby-filemagic 0.7.2 ruby lib
# stub: ext/filemagic/extconf.rb

Gem::Specification.new do |s|
  s.name = "ruby-filemagic".freeze
  s.version = "0.7.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Travis Whitton".freeze, "Jens Wille".freeze]
  s.cert_chain = ["-----BEGIN CERTIFICATE-----\nMIIDMDCCAhigAwIBAgIBADANBgkqhkiG9w0BAQUFADA+MQswCQYDVQQDDAJ3dzEb\nMBkGCgmSJomT8ixkARkWC2JsYWNrd2ludGVyMRIwEAYKCZImiZPyLGQBGRYCZGUw\nHhcNMTMwMTMxMDkyMjIyWhcNMTQwMTMxMDkyMjIyWjA+MQswCQYDVQQDDAJ3dzEb\nMBkGCgmSJomT8ixkARkWC2JsYWNrd2ludGVyMRIwEAYKCZImiZPyLGQBGRYCZGUw\nggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQDVXmfa6rbTwKOvtuGoROc1\nI4qZjgLX0BA4WecYB97PjwLJmJ1hRvf9JulVCJYYmt5ZEPPXbgi9xLbcp6ofGmnC\ni68/kbhcz20/fRUtIJ2phU3ypQTEd2pFddpL7SR2FxLkzvvg5E6nslGn7o2erDpO\n8sm610A3xsgT/eNIr9QA7k4pHh18X1KvZKmmQR4/AjVyKmKawzauKUoHHepjvjVs\ns0pVoM7UmOmrS4SafQ3OwUo37f19CVdN2/FW7z3e5+iYhKxdIFdhniX9iDWtA3Jn\n7oUOtiolhCRK4P/c30UjTCDkRkOldsWciFUasROJ5VAV2SVv7FtGHoQLDZ/++tRr\nAgMBAAGjOTA3MAkGA1UdEwQCMAAwHQYDVR0OBBYEFIAPWU4BEoYUe82hY/0EkoGd\nOo/WMAsGA1UdDwQEAwIEsDANBgkqhkiG9w0BAQUFAAOCAQEAf2YnB0mj42of22dA\nMimgJCAEgB3H5aHbZ6B5WVnFvrC2UUnhP+/kLj/6UgOfqcasy4Xh62NVGuNrf7rF\n7NMN87XwexGuU2GCpIMUd6VCTA7zMP2OWuXEcba7jT5OtiI55buO0J4CRtyeX1XF\nqwlGgx4ItcGhMTlDFXj3IkpeVtjD8O7yWE21bHf9lLURmqK/r9KjoxrrVi7+cESJ\nH19TDW3R9p594jCl1ykPs3dz/0Bk+r1HTd35Yw+yBbyprSJb4S7OcRRHCryuo09l\nNBGyZvOBuqUp0xostWSk0dfxyn/YQ7eqvQRGBhK1VGa7Tg/KYqnemDE57+VOXrua\n59wzaA==\n-----END CERTIFICATE-----\n".freeze]
  s.date = "2017-07-02"
  s.description = "Ruby bindings to the magic(4) library".freeze
  s.email = "jens.wille@gmail.com".freeze
  s.extensions = ["ext/filemagic/extconf.rb".freeze]
  s.extra_rdoc_files = ["README".freeze, "ChangeLog".freeze, "ext/filemagic/filemagic.c".freeze]
  s.files = ["ChangeLog".freeze, "README".freeze, "ext/filemagic/extconf.rb".freeze, "ext/filemagic/filemagic.c".freeze]
  s.homepage = "http://github.com/blackwinter/ruby-filemagic".freeze
  s.licenses = ["Ruby".freeze]
  s.post_install_message = "\nruby-filemagic-0.7.2 [2017-07-02]:\n\n* Fix segfault on <tt>buffer(nil)</tt> when compiled with GCC (pull request\n  #24 by Yuya Tanaka).\n\n".freeze
  s.rdoc_options = ["--title".freeze, "ruby-filemagic Application documentation (v0.7.2)".freeze, "--charset".freeze, "UTF-8".freeze, "--line-numbers".freeze, "--all".freeze, "--main".freeze, "README".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 1.9.3".freeze)
  s.rubygems_version = "2.5.2.3".freeze
  s.summary = "Ruby bindings to the magic(4) library".freeze

  s.installed_by_version = "2.5.2.3" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<hen>.freeze, [">= 0.8.7", "~> 0.8"])
      s.add_development_dependency(%q<rake>.freeze, [">= 0"])
      s.add_development_dependency(%q<rake-compiler>.freeze, [">= 0"])
      s.add_development_dependency(%q<test-unit>.freeze, [">= 0"])
    else
      s.add_dependency(%q<hen>.freeze, [">= 0.8.7", "~> 0.8"])
      s.add_dependency(%q<rake>.freeze, [">= 0"])
      s.add_dependency(%q<rake-compiler>.freeze, [">= 0"])
      s.add_dependency(%q<test-unit>.freeze, [">= 0"])
    end
  else
    s.add_dependency(%q<hen>.freeze, [">= 0.8.7", "~> 0.8"])
    s.add_dependency(%q<rake>.freeze, [">= 0"])
    s.add_dependency(%q<rake-compiler>.freeze, [">= 0"])
    s.add_dependency(%q<test-unit>.freeze, [">= 0"])
  end
end
