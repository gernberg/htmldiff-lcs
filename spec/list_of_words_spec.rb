require File.dirname(__FILE__) + '/spec_helper'

describe HTMLDiff::ListOfWords do
  describe 'breaking tags up correctly' do
    it 'separates tags' do
      input = '<p>input</p>'
      words_as_array = HTMLDiff::ListOfWords.new(input).to_a.map(&:to_s)
      expect(words_as_array).to eq %w(<p> input </p>)
    end

    it 'separates block tags' do
      input = '<p>text<div class="block_tag"><img src="something" /></div></p>'
      words_as_array = HTMLDiff::ListOfWords.new(input, {block_tag_class: 'inserted'}).to_a.map(&:to_s)
      expect(words_as_array).to eq ['<p>', 'text', '<div class="block_tag"><img src="something" /></div>', '</p>']
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
