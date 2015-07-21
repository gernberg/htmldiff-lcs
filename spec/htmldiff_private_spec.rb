# coding: utf-8
require File.dirname(__FILE__) + '/spec_helper'

describe 'HTMLDiff' do
  # Tests of internal methods and classes follow
  # These are really tests of private methods and should be considered
  # disposable if the code needs refactoring.
  describe 'internal methods' do

    let(:the_match) { double(HTMLDiff::Match) }
    let(:the_builder) { HTMLDiff::DiffBuilder.new('', '') }

    describe 'contains_unclosed_tag?' do
      it 'returns true with an open <p> tag' do
        the_builder.contains_unclosed_tag?('<p>').should be_true
      end

      it 'returns true with an unclosed closed <p> tag with an attribute' do
        the_builder.contains_unclosed_tag?('<p style="margin: 20px">').should be_true
      end

      it 'returns true with an unclosed closed <p> tag with an attribute that contains stuff' do
        the_builder.contains_unclosed_tag?('<p style="margin: 20px">blah').should be_true
      end

      it 'returns false with a properly closed <p> tag' do
        the_builder.contains_unclosed_tag?('<p></p>').should be_false
      end

      it 'returns false with a properly closed <p> tag with an attribute' do
        the_builder.contains_unclosed_tag?('<p style="margin: 20px"></p>').should be_false
      end

      it 'returns false with a properly closed <p> tag with an attribute that contains stuff' do
        the_builder.contains_unclosed_tag?('<p style="margin: 20px">blah</p>').should be_false
      end

      it 'returns false with a self closing tag' do
        the_builder.contains_unclosed_tag?('<img />').should be_false
      end
    end

    describe 'unclosed_tag' do
      it 'returns the tag when there is nothing else' do
        the_builder.unclosed_tag('<p>').should == 'p'
      end

      it 'returns the tag when there is preceding text' do
        the_builder.unclosed_tag('blah<p>').should == 'p'
      end

      it 'returns the tag when there is following text' do
        the_builder.unclosed_tag('<p>blah').should == 'p'
      end

      it 'returns the tag when there is an attribute' do
        the_builder.unclosed_tag('<p style="margin: 2em;">').should == 'p'
      end
    end

    describe 'opening_tag?' do
      it 'returns true for <p>' do
        the_builder.opening_tag?('<p>').should be_true
      end

      it 'returns true for <p> with spaces' do
        the_builder.opening_tag?(' <p> ').should be_true
      end

      it 'returns true for a tag with a url' do
        the_builder.opening_tag?('<a href="http://google.com">').should be_true
      end

      it 'returns false for </p>' do
        the_builder.opening_tag?('</p>').should be_false
      end

      it 'returns false for </p> with spaces' do
        the_builder.opening_tag?(' </p> ').should be_false
      end

      it 'returns false for internal del tags' do
        the_builder.opening_tag?('<del class="diffdel">More</del>').should be_false
      end
    end

    describe 'same_tag?' do
      it 'returns true for identical simple tags' do
        the_builder.same_tag?('<p>', '<p>').should be_true
      end

      it 'returns true for one simple and one complex tag' do
        the_builder.same_tag?('<p>', '<p style="margin: 2px;">').should be_true
      end

      it 'returns false for non matching simple tags' do
        the_builder.same_tag?('<b>', '<p>').should be_false
      end

      it 'should return false for random text' do
        the_builder.same_tag?('blah', 'blah').should be_false
      end
    end
  end
end
