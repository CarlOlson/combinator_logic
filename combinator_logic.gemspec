# -*- mode: ruby -*-

Gem::Specification.new do |s|
  s.name = "combinator_logic"
  s.version = "0.2"
  s.date = "2015-10-28"
  s.summary = "Implements a SKI combinator language in ruby."
  s.authors = ["Carl Olson"]
  s.files = Dir["lib/**/*"]
  s.require_path = 'lib'

  s.executables = ['clrb']

  s.add_runtime_dependency 'citrus', '~>3.0.2'
end
