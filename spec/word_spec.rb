require File.dirname(__FILE__) + '/spec_helper'

describe HTMLDiff::Word do
  describe 'opening_tag?' do
    it 'returns true for <p>' do
      expect(described_class.new('<p>').opening_tag?).to be_true
    end

    it 'returns true for <p> with spaces' do
      expect(described_class.new(' <p> ').opening_tag?).to be_true
    end

    it 'returns true for a tag with a url' do
      a_tag = '<a href="http://google.com">'
      expect(described_class.new(a_tag).opening_tag?).to be_true
    end

    it 'returns false for </p>' do
      expect(described_class.new('</p>').opening_tag?).to be_false
    end

    it 'returns false for </p> with spaces' do
      expect(described_class.new(' </p> ').opening_tag?).to be_false
    end

    it 'returns false for internal del tags' do
      del_tag = '<del class="diffdel">More</del>'
      expect(described_class.new(del_tag).opening_tag?).to be_false
    end
  end
end
