
Gem::Specification.new do |spec|
  spec.name          = "embulk-parser-mysqldump_tab"
  spec.version       = "0.1.0"
  spec.authors       = ["Taiji Inoue"]
  spec.summary       = "Mysqldump Tab parser plugin for Embulk"
  spec.description   = "Parses Mysqldump Tab files read by other file input plugins."
  spec.email         = ["inudog@gmail.com"]
  spec.licenses      = ["MIT"]
  # TODO set this: spec.homepage      = "https://github.com/inudog/embulk-parser-mysqldump_tab"

  spec.files         = `git ls-files`.split("\n") + Dir["classpath/*.jar"]
  spec.test_files    = spec.files.grep(%r{^(test|spec)/})
  spec.require_paths = ["lib"]

  #spec.add_dependency 'YOUR_GEM_DEPENDENCY', ['~> YOUR_GEM_DEPENDENCY_VERSION']
  spec.add_development_dependency 'embulk', ['>= 0.8.23']
  spec.add_development_dependency 'bundler', ['>= 1.10.6']
  spec.add_development_dependency 'rake', ['>= 10.0']
end
