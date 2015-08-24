require File.dirname(__FILE__) + '/spec_helper'

describe HTMLDiff::ListOfWords do
  describe 'breaking tags up correctly' do
    it 'separates tags' do
      input = '<p>input</p>'
      expect(HTMLDiff::ListOfWords.new(input).to_a.map(&:to_s)).to eq %w(<p> input </p>)
    end
  end

  describe 'contains_unclosed_tag?' do
    it 'returns true with an open <p> tag' do
      expect(described_class.new('<p>').contains_unclosed_tag?).to be_true
    end

    it 'returns true with an unclosed closed <p> tag with an attribute' do
      html = '<p style="margin: 20px">'
      expect(described_class.new(html).contains_unclosed_tag?).to be_true
    end

    it 'returns true with an unclosed closed <p> tag with an attribute '\
    'that contains stuff' do
      html = '<p style="margin: 20px">blah'
      expect(described_class.new(html).contains_unclosed_tag?).to be_true
    end

    it 'returns false with a properly closed <p> tag' do
      expect(described_class.new('<p></p>').contains_unclosed_tag?).to be_false
    end

    it 'returns false with a properly closed <p> tag with an attribute' do
      html = '<p style="margin: 20px"></p>'
      expect(described_class.new(html).contains_unclosed_tag?).to be_false
    end

    it 'returns false with a properly closed <p> tag with an attribute '\
    'that contains stuff' do
      html = '<p style="margin: 20px">blah</p>'
      expect(described_class.new(html).contains_unclosed_tag?).to be_false
    end

    it 'returns false with a self closing tag' do
      expect(described_class.new('<img>').contains_unclosed_tag?).to be_false
    end
  end
end