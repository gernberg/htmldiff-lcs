require 'spec_helper'

describe 'Treating a block tag as a single item' do

  it 'shows the whole div as an insert' do
    oldv = '<p>text</p>'
    newv = '<p>text<div class="block_tag"><img src="something" /></div></p>'
    diff = HTMLDiff.diff(oldv, newv, {block_tag_classes: ['inserted']})
    expect(diff).to eq('<p>text<ins class="diffins"><div class="block_tag"><img src="something" /></div></ins></p>')
  end
end