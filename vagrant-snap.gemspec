# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{vagrant-snap}
  s.version = "0.01"

  s.required_rubygems_version = Gem::Requirement.new(">= 1.2") if s.respond_to? :required_rubygems_version=
  s.authors = ["t9md"]
  s.date = %q{2011-06-06}
  s.description = %q{vagrant snapshot managemen plugin}
  s.email = %q{taqumd@gmail.com}
  s.extra_rdoc_files = ["LICENSE.txt", "README.md", "lib/vagrant_init.rb", "lib/vagrant_snap.rb"]
  s.files = ["LICENSE.txt", "Manifest", "README.md", "VERSION", "lib/vagrant_init.rb", "lib/vagrant_snap.rb", "Rakefile", "vagrant-snap.gemspec"]
  s.homepage = %q{http://github.com/t9md/vagrant-snap}
  s.rdoc_options = ["--line-numbers", "--inline-source", "--title", "Vagrant-snap", "--main", "README.md"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.7}
  s.summary = %q{vagrant snapshot managemen plugin}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<vagrant>, [">= 0"])
      s.add_runtime_dependency(%q<colored>, [">= 0"])
    else
      s.add_dependency(%q<vagrant>, [">= 0"])
      s.add_dependency(%q<colored>, [">= 0"])
    end
  else
    s.add_dependency(%q<vagrant>, [">= 0"])
    s.add_dependency(%q<colored>, [">= 0"])
  end
end
