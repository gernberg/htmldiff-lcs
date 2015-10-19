# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = 'htmldiff-lcs'
  s.version = '0.0.1'

  if s.respond_to? :required_rubygems_version=
    s.required_rubygems_version = Gem::Requirement.new('>= 0')
  end
  s.authors = ['Nathan Herald', 'Matt Gibson', 'Nat Budin']
  s.autorequire = 'htmldiff'
  s.date = '2015-10-19'
  s.description = 'HTML diffs of text, based on diff-lcs'
  s.email = 'natbudin@gmail.com'
  s.extra_rdoc_files = %w(README LICENSE TODO)
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.extra_rdoc_files = [
    "README.md"
  ]
  
  s.has_rdoc = true
  s.homepage = 'http://github.com/nbudin/htmldiff-lcs'
  s.require_paths = ['lib']
  s.rubygems_version = '1.3.1'
  s.summary = 'HTML diffs of text (borrowed from a wiki software '\
  'I no longer remember)'
  
  s.add_runtime_dependency('diff-lcs', ['>= 0'])

  s.specification_version = 2 if s.respond_to? :specification_version
end
