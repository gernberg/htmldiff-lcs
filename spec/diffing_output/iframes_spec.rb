require File.dirname(__FILE__) + '/../spec_helper'

describe 'HTMLDiff' do
  describe 'diff' do
    describe 'iframes' do
      it 'wraps iframe inserts' do
        oldv = 'a b c'
        newv = 'a b <iframe src="some_url"></iframe> c'
        diff = HTMLDiff.diff(oldv, newv)
        expect(diff).to eq('a b <ins class="diffins"><iframe src="some_url"></iframe></ins><ins class="diffins"> </ins>c')
      end

      it 'wraps iframe inserts with extra stuff' do
        oldv = ''
        newv = '
      <div class="iframe-wrap scribd">
      <div class="iframe-aspect-ratio">
      </div>
      <iframe src="url"></iframe>
      </div>
  '
        diff = HTMLDiff.diff(oldv, newv)
        expect(diff).to eq('<ins class="diffins">
      </ins><ins class="diffins"><div class="iframe-wrap scribd"><ins class="diffins">
      </ins><div class="iframe-aspect-ratio"><ins class="diffins">
      </ins></div><ins class="diffins">
      </ins><ins class="diffins"><iframe src="url"></iframe></ins><ins class="diffins">
      </ins></div><ins class="diffins">
  </ins></ins>')
      end
    end
  end
end
