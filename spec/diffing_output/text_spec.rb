require File.dirname(__FILE__) + '/../spec_helper'

describe 'HTMLDiff' do
  describe 'diff' do
    describe 'text' do
      it 'should diff text' do
        diff = HTMLDiff.diff('a word is here', 'a nother word is there')
        expect(diff).to eq("a<ins class=\"diffins\"> nother</ins> word is "\
        "<del class=\"diffmod\">here</del><ins class=\"diffmod\">there</ins>")
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
        expect(diff).to eq("这<del class=\"diffdel\">个</del>是中<del "\
        "class=\"diffmod\">文</del><ins class=\"diffmod\">国语</ins>内容<del "\
        "class=\"diffmod\">, Ruby</del><ins class=\"diffmod\">，Ruby</ins> is "\
        "the <del class=\"diffmod\">bast</del><ins class=\"diffmod\">best "\
        'language.</ins>')
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
