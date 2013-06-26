# coding: utf-8
require File.dirname(__FILE__) + '/spec_helper'
require 'htmldiff'

class TestDiff
  extend HTMLDiff
end

describe "htmldiff" do

  it "should diff text" do

    diff = TestDiff.diff('a word is here', 'a nother word is there')
    diff.should == "a<ins class=\"diffins\"> nother</ins> word is <del class=\"diffmod\">here</del><ins class=\"diffmod\">there</ins>"

  end

  it "should insert a letter and a space" do
    diff = TestDiff.diff('a c', 'a b c')
    diff.should == "a <ins class=\"diffins\">b </ins>c"
  end

  it "should remove a letter and a space" do
    diff = TestDiff.diff('a b c', 'a c')
    diff.should == "a <del class=\"diffdel\">b </del>c"
  end

  it "should change a letter" do
    diff = TestDiff.diff('a b c', 'a d c')
    diff.should == "a <del class=\"diffmod\">b</del><ins class=\"diffmod\">d</ins> c"
  end

  it "should support Chinese" do
    diff = TestDiff.diff('这个是中文内容, Ruby is the bast', '这是中国语内容，Ruby is the best language.')
    diff.should == "这<del class=\"diffdel\">个</del>是中<del class=\"diffmod\">文</del><ins class=\"diffmod\">国语</ins>内容<del class=\"diffmod\">, Ruby</del><ins class=\"diffmod\">，Ruby</ins> is the <del class=\"diffmod\">bast</del><ins class=\"diffmod\">best language.</ins>"
  end

  it "should wrap deleted tags" do
    doc_a = %|<p> Test Paragraph </p><p>More Stuff</p>|
    doc_b = %|<p>Nothing!</p>|
    diff = TestDiff.diff(doc_a, doc_b)
    diff.should == %|<p><del class="diffmod"> Test Paragraph </del><ins class="diffmod">Nothing!</ins></p><del class="diffdel"><p><del class="diffdel">More Stuff</del></p></del>|
  end

  it "should wrap inserted tags" do
    doc_a = %|<p>Nothing!</p>|
    doc_b = %|<p> Test Paragraph </p><p>More Stuff</p>|
    diff = TestDiff.diff(doc_a, doc_b)
    diff.should == %|<p><del class="diffmod">Nothing!</del><ins class="diffmod"> Test Paragraph </ins></p><ins class="diffins"><p><ins class="diffins">More Stuff</ins></p></ins>|
  end

  it "should wrap deleted tags even with text around" do
    doc_a = %|<p> Test Paragraph </p>weee<p>More Stuff</p>|
    doc_b = %|<p>Nothing!</p>weee|
    diff = TestDiff.diff(doc_a, doc_b)
    diff.should == %|<p><del class="diffmod"> Test Paragraph </del><ins class="diffmod">Nothing!</ins></p>weee<del class="diffdel"><p><del class="diffdel">More Stuff</del></p></del>|

    doc_a = %|<p> Test Paragraph </p>weee<p>More Stuff</p>|
    doc_b = %|<p>Nothing!</p>|
    diff = TestDiff.diff(doc_a, doc_b)
    diff.should == %|<p><del class="diffmod"> Test Paragraph </del><ins class="diffmod">Nothing!</ins></p><del class="diffdel">weee</del><del class="diffdel"><p><del class="diffdel">More Stuff</del></p></del>|

    doc_a = %|<p> Test Paragraph </p>weee<p>More Stuff</p>asd|
    doc_b = %|<p>Nothing!</p>weee asd|
    diff = TestDiff.diff(doc_a, doc_b)
    diff.should == %|<p><del class="diffmod"> Test Paragraph </del><ins class="diffmod">Nothing!</ins></p>weee<del class="diffdel"><p><del class="diffdel">More</del></del> <del class="diffdel">Stuff</del><del class="diffdel"></p></del>asd|
  end

  it "should wrap inserted tags even with text around" do
    doc_a = %|<p>Nothing!</p>weee|
    doc_b = %|<p> Test Paragraph </p>weee<p>More Stuff</p>|
    diff = TestDiff.diff(doc_a, doc_b)
    diff.should == %|<p><del class="diffmod">Nothing!</del><ins class="diffmod"> Test Paragraph </ins></p>weee<ins class="diffins"><p><ins class="diffins">More Stuff</ins></p></ins>|
  end

end
