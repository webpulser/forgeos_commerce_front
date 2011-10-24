$:.push File.expand_path("../lib", __FILE__)

require "forgeos/commerce_front/version"

Gem::Specification.new do |s|
  s.add_dependency 'forgeos_commerce', '1.9.0'

  s.name = 'forgeos_commerce_front'
  s.version = Forgeos::CommerceFront::VERSION
  s.date = '2011-10-20'

  s.summary = 'CommerceFront of Forgeos plugins suite'
  s.description = 'Forgeos Commerce Front provide a configurable eCommerce website'

  s.authors = ['Cyril LEPAGNOT', 'Jean Charles Lefrancois', 'Sebastien Deloor', 'Garry Ysenbaert']
  s.email = 'dev@webpulser.com'
  s.homepage = 'http://github.com/webpulser/forgeos_commerce_front'

  s.files = Dir['{app,lib,config,db,recipes}/**/*', 'README*', 'LICENSE', 'COPYING*', 'MIT-LICENSE', 'Gemfile']
  s.test_files = Dir['test/**/*']
end

