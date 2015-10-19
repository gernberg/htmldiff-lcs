require File.dirname(__FILE__) + '/../spec_helper'

describe 'HTMLDiff' do
  describe 'diff' do
    describe 'text' do
      it 'should diff text' do
        diff = HTMLDiff.diff('a word is here', 'a nother word is there')
        expect(diff).to eq("a <del class=\"diffmod\">word is here</del>"\
        "<ins class=\"diffmod\">nother word is there</ins>")
      end

      it 'should insert a letter and a space' do
        diff = HTMLDiff.diff('a c', 'a b c')
        expect(diff).to eq("a <ins class=\"diffins\">b </ins>c")
      end

      it 'should remove a letter and a space' do
        diff = HTMLDiff.diff('a b c', 'a c')
        expect(diff).to eq("a <del class=\"diffdel\">b </del>c")
      end

      it 'should change a letter' do
        diff = HTMLDiff.diff('a b c', 'a d c')
        expect(diff).to eq("a <del class=\"diffmod\">b</del><ins "\
        "class=\"diffmod\">d</ins> c")
      end

      it 'supports Chinese' do
        diff = HTMLDiff.diff('这个是中文内容, Ruby is the bast',
                             '这是中国语内容，Ruby is the best language.')
        expect(diff).to eq("这<del class=\"diffmod\">个是中文内容, "\
        "Ruby is the bast</del><ins class=\"diffmod\">是中国语内容，"\
        'Ruby is the best language.</ins>')
      end

      it 'puts long bit of replaced text together, rather than '\
      'breaking on word boundaries' do
        diff = HTMLDiff.diff('a long bit of text',
                             'some totally different text')
        expected = '<del class="diffmod">a long bit of</del>'\
        '<ins class="diffmod">some totally different</ins> text'
        expect(diff).to eq(expected)
      end
    end
  end
end
