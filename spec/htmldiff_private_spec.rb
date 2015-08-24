# coding: utf-8
require File.dirname(__FILE__) + '/spec_helper'

# Tests of internal methods and classes follow
# These are really tests of private methods and should be considered
# disposable if the code needs refactoring.
describe 'internal methods' do
  let(:the_match) { double(HTMLDiff::Match) }
  let(:the_builder) { HTMLDiff::DiffBuilder.new('', '') }



  describe 'same_tag?' do
    it 'returns true for identical simple tags' do
      expect(the_builder.same_tag?('<p>', '<p>')).to be_true
    end

    it 'returns true for one simple and one complex tag' do
      tag = '<p>'
      tag_with_attrs = '<p style="margin: 2px;">'
      expect(the_builder.same_tag?(tag, tag_with_attrs)).to be_true
    end

    it 'returns false for non matching simple tags' do
      expect(the_builder.same_tag?('<b>', '<p>')).to be_false
    end

    it 'should return false for random text' do
      expect(the_builder.same_tag?('blah', 'blah')).to be_false
    end
  end
end
