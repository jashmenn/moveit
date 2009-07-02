# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{moveit}
  s.version = "0.0.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Nate Murray"]
  s.date = %q{2009-07-02}
  s.email = %q{nate@natemurray.com}
  s.extra_rdoc_files = [
    "LICENSE",
    "README.mkd"
  ]
  s.files = [
    "LICENSE",
    "README.mkd",
    "Rakefile",
    "VERSION.yml",
    "lib/has_logger.rb",
    "lib/moveit.rb",
    "spec/moveit_spec.rb",
    "spec/spec_helper.rb"
  ]
  s.has_rdoc = true
  s.homepage = %q{http://github.com/jashmenn/moveit}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.2}
  s.summary = %q{`FileUtils` for all the other file systems in your life: scp, ssh, s3, hdfs}
  s.test_files = [
    "spec/moveit_spec.rb",
    "spec/spec_helper.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
