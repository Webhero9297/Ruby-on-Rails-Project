# encoding: UTF-8
$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "modondo_mailgun/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "modondo_mailgun"
  s.version     = ModondoMailgun::VERSION
  s.authors     = ["Jörgen Nilsson", "Henrik Zagerholm"]
  s.email       = ["jorgen@modondo.com"]
  s.homepage    = "http://www.modondo.com"
  s.summary     = "Mailgun http API support for ActionMailer"
  s.description = "Use the Mailgun e-email service directly with ActionMailer"

  s.files = Dir["{app,config,db,lib}/**/*"] + ["MIT-LICENSE", "Rakefile", "README.rdoc"]

  s.add_dependency "rails", "~> 3.2.3"

  s.add_development_dependency "sqlite3"
end
