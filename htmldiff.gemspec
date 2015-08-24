# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = 'htmldiff'
  s.version = '0.0.1'

  if s.respond_to? :required_rubygems_version=
    s.required_rubygems_version = Gem::Requirement.new('>= 0')
  end
  s.authors = ['Nathan Herald']
  s.autorequire = 'htmldiff'
  s.date = '2008-11-21'
  s.description = 'HTML diffs of text (borrowed from a wiki software '\
  'I no longer remember)'
  s.email = 'nathan@myobie.com'
  s.extra_rdoc_files = %w(README LICENSE TODO)
  s.files = %w(LICENSE README Rakefile TODO lib/htmldiff.rb '\
'spec/htmldiff_spec.rb spec/spec_helper.rb)
  s.has_rdoc = true
  s.homepage = 'http://github.com/myobie/htmldiff'
  s.require_paths = ['lib']
  s.rubygems_version = '1.3.1'
  s.summary = 'HTML diffs of text (borrowed from a wiki software '\
  'I no longer remember)'

  s.specification_version = 2 if s.respond_to? :specification_version
end
