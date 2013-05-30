lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'jst/version'

Gem::Specification.new do |s|
  s.name        = 'jst-parser'
  s.version     = JST::VERSION
  s.platform    = Gem::Platform::RUBY
  s.date        = '2013-05-30'

  s.summary     = 'Joint Service Transcript (JST) parsing utility.'
  s.description = 'A PDF parser for the Joint Service Transcript (JST), a standardized
                  service transcript for Army, Marine Corps, Navy, and Coast Guard personnel. 
                  (https://jst.doded.mil/faq.html)
                  Returns accumulated skills, military experience, and education as JSON.'
  s.authors     = ['Chris Little']
  s.email       = 'razenghan@gmail.com'
  s.homepage    = 'http://rubygems.org/gems/jst-parser'

  s.files         = `git ls-files`.split($/)
  s.test_files  = s.files.grep(%r{^(test|spec|features)/})
  s.require_path = 'lib'

  # PDF Parser
  s.add_dependency 'pdf-reader', '~> 1.3.3'

  # Development
  s.add_development_dependency "bundler", "~> 1.3"
  s.add_development_dependency "rake"
end