# encoding: UTF-8
Gem::Specification.new do |s|
  s.platform    = Gem::Platform::RUBY
  s.name        = 'spree_al_import'
  s.version     = '1.1.2'
  s.summary     = 'My import in spree'
  s.description = 'My import in spree'
  s.required_ruby_version = '>= 1.8.7'

  s.author    = '--al--'
  s.email     = 'mister-al@ya.ru'
  s.homepage  = 'http://www.spreecommerce.com'

  s.files       = `git ls-files`.split("\n")
  #s.test_files  = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.require_path = 'lib'
  s.requirements << 'none'

  s.add_dependency 'spree_core', '~> 1.1.1'
  s.add_dependency 'spree_auth', '~> 1.1.1'
  s.add_dependency 'russian', '~> 0.6.0'
  #s.add_development_dependency 'capybara', '1.0.1'
  #s.add_development_dependency 'factory_girl', '~> 2.6.4'
  #s.add_development_dependency 'ffaker'
  s.add_development_dependency 'rspec-rails',  '~> 2.9'
  #s.add_development_dependency 'sqlite3'
end

