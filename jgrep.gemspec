require 'date'

Gem::Specification.new do |s|
    s.name = "jgrep"

    s.version = "1.5.2"
    s.date = Date.today.to_s

    s.summary = "Filter JSON documents with a simple logical language"
    s.description = "Compare a list of json documents to a simple logical language and returns matches as output"
    s.homepage = "https://github.com/ploubser/JSON-Grep"
    s.license = "Apache-2.0"

    s.authors = ["P Loubser", "Dominic Cleal", "R.I. Pienaar"]
    s.email = ["ploubser@gmail.com", "dominic@cleal.org", "rip@devco.net"]

    s.files = `git ls-files`.split("\n") - Dir[".*", "Gem*", "*.gemspec"]
    s.extra_rdoc_files = [
        "CHANGELOG.markdown",
        "README.markdown",
    ]
    s.require_paths = ["lib"]
    s.executables = ["jgrep"]
    s.default_executable = "jgrep"
    s.has_rdoc = true
end
