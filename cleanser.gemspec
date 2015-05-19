name = "cleanser"
require "./lib/#{name.gsub("-","/")}/version"

Gem::Specification.new name, Cleanser::VERSION do |s|
  s.summary = "Find polluting test by bisecting your tests"
  s.authors = ["Michael Grosser"]
  s.email = "michael@grosser.it"
  s.homepage = "https://github.com/grosser/#{name}"
  s.files = `git ls-files lib/ bin/ MIT-LICENSE`.split("\n")
  s.executables << 'cleanser'
  s.license = "MIT"
  s.required_ruby_version = '>= 1.9.3'
end
