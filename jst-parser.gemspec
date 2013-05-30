Gem::Specification.new do |s|
  s.name        = 'jst-parser'
  s.version     = '0.0.1'
  s.date        = '2013-05-30'
  s.summary     = ''
  s.summary     = 'Joint Service Transcript (JST) parsing utility.'
  s.description = 'A PDF parser for the Joint Service Transcript (JST), a standardized
                  service transcript for Army, Marine Corps, Navy, and Coast Guard personnel. 
                  (https://jst.doded.mil/faq.html)
                  Returns accumulated skills, military experience, and education as JSON.'
  s.authors     = ['Chris Little']
  s.email       = 'razenghan@gmail.com'
  s.files       = Dir['{lib}/**/*.rb', 'LICENSE', '*.md']
  s.homepage    = 'http://rubygems.org/gems/jst-parser'

  #s.add_dependency 'json', '~> 1.7.6'
end