require File.dirname(__FILE__) + '/../spec_helper'

describe 'HTMLDiff' do
  describe 'diff' do
    describe 'img tags' do
      it 'should support img tags insertion' do
        oldv = 'a b c'
        newv = 'a b <img src="some_url" /> c'
        diff = HTMLDiff.diff(oldv, newv)
        expect(diff).to eq('a b <ins class="diffins"><img src="some_url" /></ins><ins class="diffins"> </ins>c')
      end

      it 'wraps img tags inside other tags' do
        oldv = '<p>text</p>'
        newv = '<p>text<img src="something" /></p>'
        diff = HTMLDiff.diff(oldv, newv)
        expect(diff).to eq('<p>text<ins class="diffins"><img src="something" /></ins></p>')
      end

      it 'wraps img tags inserted with other tags' do
        oldv = 'text'
        newv = 'text<p><img src="something" /></p>'
        diff = HTMLDiff.diff(oldv, newv)
        expect(diff).to eq('text<ins class="diffins"><p><ins class="diffins"><img src="something" /></ins></p></ins>')
      end

      it 'wraps img tags inserted with other tags and new lines' do
        oldv = 'text'
        newv = %(text<p>\r\n<img src="something" />\r\n</p>)
        diff = HTMLDiff.diff(oldv, newv)
        expect(diff).to eq(%(text<ins class="diffins"><p><ins class="diffins">\r\n<img src="something" />\r\n</ins></p></ins>))
      end

      it 'wraps badly terminated img tags inserted with other tags and new lines' do
        oldv = 'text'
        newv = %(text<p>\r\n<img src="something">\r\n</p>)
        diff = HTMLDiff.diff(oldv, newv)
        expect(diff).to eq(%(text<ins class="diffins"><p><ins class="diffins">\r\n<img src="something">\r\n</ins></p></ins>))
      end

      it 'supports img tags deletion' do
        oldv = 'a b <img src="some_url" /> c'
        newv = 'a b c'
        diff = HTMLDiff.diff(oldv, newv)
        expect(diff).to eq('a b <del class="diffdel"><img src="some_url" /></del><del class="diffdel"> </del>c')
      end
    end
  end
end
