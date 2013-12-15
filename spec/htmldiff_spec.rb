# coding: utf-8
require File.dirname(__FILE__) + '/spec_helper'
require 'htmldiff'

describe "HTMLDiff" do

  describe 'diff' do
    describe 'text' do
      it "should diff text" do
        diff = HTMLDiff.diff('a word is here', 'a nother word is there')
        diff.should == "a<ins class=\"diffins\"> nother</ins> word is <del class=\"diffmod\">here</del><ins class=\"diffmod\">there</ins>"
      end

      it "should insert a letter and a space" do
        diff = HTMLDiff.diff('a c', 'a b c')
        diff.should == "a <ins class=\"diffins\">b </ins>c"
      end

      it "should remove a letter and a space" do
        diff = HTMLDiff.diff('a b c', 'a c')
        diff.should == "a <del class=\"diffdel\">b </del>c"
      end

      it "should change a letter" do
        diff = HTMLDiff.diff('a b c', 'a d c')
        diff.should == "a <del class=\"diffmod\">b</del><ins class=\"diffmod\">d</ins> c"
      end

      it "supports Chinese" do
        diff = HTMLDiff.diff('这个是中文内容, Ruby is the bast', '这是中国语内容，Ruby is the best language.')
        diff.should == "这<del class=\"diffdel\">个</del>是中<del class=\"diffmod\">文</del><ins class=\"diffmod\">国语</ins>内容<del class=\"diffmod\">, Ruby</del><ins class=\"diffmod\">，Ruby</ins> is the <del class=\"diffmod\">bast</del><ins class=\"diffmod\">best language.</ins>"
      end
    end

    describe 'simple tags' do
      it "wraps deleted tags" do
        doc_a = %|<p> Test Paragraph </p><p>More Stuff</p>|
        doc_b = %|<p>Nothing!</p>|
        diff = HTMLDiff.diff(doc_a, doc_b)
        diff.should == %|<p><del class="diffmod"> Test Paragraph </del><ins class="diffmod">Nothing!</ins></p><del class="diffdel"><p><del class="diffdel">More Stuff</del></p></del>|
      end

      it "wraps inserted tags" do
        doc_a = %|<p>Nothing!</p>|
        doc_b = %|<p> Test Paragraph </p><p>More Stuff</p>|
        diff = HTMLDiff.diff(doc_a, doc_b)
        diff.should == %|<p><del class="diffmod">Nothing!</del><ins class="diffmod"> Test Paragraph </ins></p><ins class="diffins"><p><ins class="diffins">More Stuff</ins></p></ins>|
      end

      describe "wrapping deleted tags even with text around them" do
        it 'changes inside plus deleted consecutive paragraph, leaving text afterwards' do
          doc_a = %|<p> Test Paragraph </p>weee<p>More Stuff</p>|
          doc_b = %|<p>Nothing!</p>weee|
          diff = HTMLDiff.diff(doc_a, doc_b)
          diff.should == %|<p><del class="diffmod"> Test Paragraph </del><ins class="diffmod">Nothing!</ins></p>weee<del class="diffdel"><p><del class="diffdel">More Stuff</del></p></del>|
        end

        it 'changes inside plus deleted consecutive paragraph, plus deleted consecutive text' do
          doc_a = %|<p> Test Paragraph </p>weee<p>More Stuff</p>|
          doc_b = %|<p>Nothing!</p>|
          diff = HTMLDiff.diff(doc_a, doc_b)
          diff.should == %|<p><del class="diffmod"> Test Paragraph </del><ins class="diffmod">Nothing!</ins></p><del class="diffdel">weee</del><del class="diffdel"><p><del class="diffdel">More Stuff</del></p></del>|
        end

        it 'changes inside plus deleted consecutive paragraph, leaving text afterwards with some extra text' do
          doc_a = %|<p> Test Paragraph </p>weee<p>More Stuff</p>asd|
          doc_b = %|<p>Nothing!</p>weee asd|
          diff = HTMLDiff.diff(doc_a, doc_b)
          diff.should == %|<p><del class="diffmod"> Test Paragraph </del><ins class="diffmod">Nothing!</ins></p>weee<p><del class="diffdel">More</del> <del class="diffdel">Stuff</del></p>asd|
        end
      end

      it "wraps inserted tags even with text around" do
        doc_a = %|<p>Nothing!</p>weee|
        doc_b = %|<p> Test Paragraph </p>weee<p>More Stuff</p>|
        diff = HTMLDiff.diff(doc_a, doc_b)
        diff.should == %|<p><del class="diffmod">Nothing!</del><ins class="diffmod"> Test Paragraph </ins></p>weee<ins class="diffins"><p><ins class="diffins">More Stuff</ins></p></ins>|
      end

      #
      #describe 'replacing tags' do
      #  it 'highlights the tags as well as their content' do
      #    doc_a = %|text <p>Nothing!</p> text|
      #    doc_b = %|text <h1>Nothing!</h1> text|
      #    diff = HTMLDiff.diff(doc_a, doc_b)
      #    diff.should == %|text <del class="diffmod"><p>Nothing!</p></del><ins class="diffmod"><h1>Nothing!</h1></ins> text|
      #  end
      #end

      describe 'changing the attributes of tags' do
        it 'ignores a tag with new attributes' do
          doc_a = %|text <p>Nothing!</p> text|
          doc_b = %|text <p style="margin-left: 20px">Nothing!</p> text|
          diff = HTMLDiff.diff(doc_a, doc_b)
          diff.should == %|text <p style="margin-left: 20px">Nothing!</p> text|
        end
      end
    end

    describe 'tables' do
      it "wraps deleted table tags" do
        doc_a = %|<p> Test Paragraph </p>
        <p> </p>
        <table><tbody><tr><td>hello</td><td>bye</td></tr></tbody></table>
        <p>&nbsp;</p>
        |
        doc_b = %|<p>Nothing!</p>|
        diff = HTMLDiff.diff(doc_a, doc_b)
        diff.should == %|<p><del class="diffmod"> Test Paragraph </del><ins class="diffmod">Nothing!</ins></p><del class="diffdel">
        </del><del class="diffdel"><p><del class="diffdel"> </del></p><del class="diffdel">
        </del><table><tbody><tr><td><del class="diffdel">hello</del></td><td><del class="diffdel">bye</del></td></tr></tbody></table><del class="diffdel">
        </del><p><del class="diffdel">&nbsp;</del></p><del class="diffdel">
        </del></del>|
      end

      it "should wrap deleted table rows" do
        doc_a = %|<p>my table</p>
        <table>
        <tbody>
        <tr><td>hello</td><td>bye</td></tr>
        <tr><td>remove</td><td>me</td></tr>
        </tbody>
        </table>|
        doc_b = %|<p>my table</p>
        <table>
        <tbody>
        <tr><td>hello</td><td>bye</td></tr>
        </tbody>
        </table>|
        diff = HTMLDiff.diff(doc_a, doc_b)
        diff.should == %|<p>my table</p>
        <table>
        <tbody>
        <tr><td>hello</td><td>bye</td></tr>
        <del class="diffdel"><tr><td><del class="diffdel">remove</del></td><td><del class="diffdel">me</del></td></tr><del class="diffdel">
        </del></del></tbody>
        </table>|
      end
    end

    describe 'img tags' do
      it "should support img tags insertion" do
        oldv = 'a b c'
        newv = 'a b <img src="some_url" /> c'
        diff = HTMLDiff.diff(oldv, newv)
        diff.should == %|a b <ins class="diffins"><img src="some_url" /></ins><ins class="diffins"> </ins>c|
      end

      it 'wraps img tags inside other tags' do
        oldv = %|<p>text</p>|
        newv = %|<p>text<img src="something" /></p>|
        diff = HTMLDiff.diff(oldv, newv)
        diff.should == %|<p>text<ins class="diffins"><img src="something" /></ins></p>|
      end

      it 'wraps img tags inserted with other tags' do
        oldv = %|text|
        newv = %|text<p><img src="something" /></p>|
        diff = HTMLDiff.diff(oldv, newv)
        diff.should == %|text<ins class="diffins"><p><ins class="diffins"><img src="something" /></ins></p></ins>|
      end

      it 'wraps img tags inserted with other tags and new lines' do
        oldv = %|text|
        newv = %|text<p>\r\n<img src="something" />\r\n</p>|
        diff = HTMLDiff.diff(oldv, newv)
        diff.should == %|text<ins class="diffins"><p><ins class="diffins">\r\n<img src="something" />\r\n</ins></p></ins>|
      end

      it 'wraps badly terminated img tags inserted with other tags and new lines' do
        oldv = %|text|
        newv = %|text<p>\r\n<img src="something">\r\n</p>|
        diff = HTMLDiff.diff(oldv, newv)
        diff.should == %|text<ins class="diffins"><p><ins class="diffins">\r\n<img src="something">\r\n</ins></p></ins>|
      end

      it "supports img tags deletion" do
        oldv = 'a b <img src="some_url" /> c'
        newv = 'a b c'
        diff = HTMLDiff.diff(oldv, newv)
        diff.should == %|a b <del class="diffdel"><img src="some_url" /></del><del class="diffdel"> </del>c|
      end
    end

    describe 'iframes' do
      it 'wraps iframe inserts' do
        oldv = 'a b c'
        newv = 'a b <iframe src="some_url"></iframe> c'
        diff = HTMLDiff.diff(oldv, newv)
        diff.should == %|a b <ins class="diffins"><iframe src="some_url"></iframe></ins><ins class="diffins"> </ins>c|
      end

      it 'wraps iframe inserts with extra stuff' do
        oldv = ''
        newv = %|
      <div class="iframe-wrap scribd">
      <div class="iframe-aspect-ratio">
      </div>
      <iframe src="url"></iframe>
      </div>
  |
        diff = HTMLDiff.diff(oldv, newv)
        diff.should == %|<ins class="diffins">
      </ins><ins class="diffins"><div class="iframe-wrap scribd"><ins class="diffins">
      </ins><div class="iframe-aspect-ratio"><ins class="diffins">
      </ins></div><ins class="diffins">
      </ins><ins class="diffins"><iframe src="url"></iframe></ins><ins class="diffins">
      </ins></div><ins class="diffins">
  </ins></ins>|

      end
    end
  end

  # Tests of internal methods and classes follow:

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
