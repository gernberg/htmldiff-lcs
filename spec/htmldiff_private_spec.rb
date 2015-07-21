# coding: utf-8
require File.dirname(__FILE__) + '/spec_helper'

# Tests of internal methods and classes follow
# These are really tests of private methods and should be considered
# disposable if the code needs refactoring.
describe 'internal methods' do
  let(:the_match) { double(HTMLDiff::Match) }
  let(:the_builder) { HTMLDiff::DiffBuilder.new('', '') }

  describe 'contains_unclosed_tag?' do
    it 'returns true with an open <p> tag' do
      expect(the_builder.contains_unclosed_tag?('<p>')).to be_true
    end

    it 'returns true with an unclosed closed <p> tag with an attribute' do
      html = '<p style="margin: 20px">'
      expect(the_builder.contains_unclosed_tag?(html)).to be_true
    end

    it 'returns true with an unclosed closed <p> tag with an attribute '\
    'that contains stuff' do
      html = '<p style="margin: 20px">blah'
      expect(the_builder.contains_unclosed_tag?(html)).to be_true
    end

    it 'returns false with a properly closed <p> tag' do
      expect(the_builder.contains_unclosed_tag?('<p></p>')).to be_false
    end

    it 'returns false with a properly closed <p> tag with an attribute' do
      html = '<p style="margin: 20px"></p>'
      expect(the_builder.contains_unclosed_tag?(html)).to be_false
    end

    it 'returns false with a properly closed <p> tag with an attribute '\
    'that contains stuff' do
      html = '<p style="margin: 20px">blah</p>'
      expect(the_builder.contains_unclosed_tag?(html)).to be_false
    end

    it 'returns false with a self closing tag' do
      expect(the_builder.contains_unclosed_tag?('<img>')).to be_false
    end
  end

  describe 'unclosed_tag' do
    it 'returns the tag when there is nothing else' do
      expect(the_builder.unclosed_tag('<p>')).to eq('p')
    end

    it 'returns the tag when there is preceding text' do
      expect(the_builder.unclosed_tag('blah<p>')).to eq('p')
    end

    it 'returns the tag when there is following text' do
      expect(the_builder.unclosed_tag('<p>blah')).to eq('p')
    end

    it 'returns the tag when there is an attribute' do
      expect(the_builder.unclosed_tag('<p style="margin: 2em;">')).to eq('p')
    end
  end

  describe 'opening_tag?' do
    it 'returns true for <p>' do
      expect(the_builder.opening_tag?('<p>')).to be_true
    end

    it 'returns true for <p> with spaces' do
      expect(the_builder.opening_tag?(' <p> ')).to be_true
    end

    it 'returns true for a tag with a url' do
      a_tag = '<a href="http://google.com">'
      expect(the_builder.opening_tag?(a_tag)).to be_true
    end

    it 'returns false for </p>' do
      expect(the_builder.opening_tag?('</p>')).to be_false
    end

    it 'returns false for </p> with spaces' do
      expect(the_builder.opening_tag?(' </p> ')).to be_false
    end

    it 'returns false for internal del tags' do
      del_tag = '<del class="diffdel">More</del>'
      expect(the_builder.opening_tag?(del_tag)).to be_false
    end
  end

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
