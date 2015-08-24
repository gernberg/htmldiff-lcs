require File.dirname(__FILE__) + '/../spec_helper'

describe 'HTMLDiff' do
  describe 'diff' do
    describe 'simple tags' do
      it 'wraps deleted tags' do
        doc_a = '<p> Test Paragraph </p><p>More Stuff</p>'
        doc_b = '<p>Nothing!</p>'
        diff = HTMLDiff.diff(doc_a, doc_b)
        expect(diff).to eq('<p><del class="diffmod"> Test Paragraph </del><ins class="diffmod">Nothing!</ins></p><del class="diffdel"><p><del class="diffdel">More Stuff</del></p></del>')
      end

      it 'wraps inserted tags' do
        doc_a = '<p>Nothing!</p>'
        doc_b = '<p> Test Paragraph </p><p>More Stuff</p>'
        diff = HTMLDiff.diff(doc_a, doc_b)
        expect(diff).to eq('<p><del class="diffmod">Nothing!</del><ins class="diffmod"> Test Paragraph </ins></p><ins class="diffins"><p><ins class="diffins">More Stuff</ins></p></ins>')
      end

      describe 'wrapping deleted tags even with text around them' do
        it 'changes inside plus deleted consecutive paragraph, leaving text afterwards' do
          doc_a = '<p> Test Paragraph </p>weee<p>More Stuff</p>'
          doc_b = '<p>Nothing!</p>weee'
          diff = HTMLDiff.diff(doc_a, doc_b)
          expect(diff).to eq('<p><del class="diffmod"> Test Paragraph </del><ins class="diffmod">Nothing!</ins></p>weee<del class="diffdel"><p><del class="diffdel">More Stuff</del></p></del>')
        end

        it 'changes inside plus deleted consecutive paragraph, plus deleted consecutive text' do
          doc_a = '<p> Test Paragraph </p>weee<p>More Stuff</p>'
          doc_b = '<p>Nothing!</p>'
          diff = HTMLDiff.diff(doc_a, doc_b)
          expect(diff).to eq('<p><del class="diffmod"> Test Paragraph </del><ins class="diffmod">Nothing!</ins></p><del class="diffdel">weee</del><del class="diffdel"><p><del class="diffdel">More Stuff</del></p></del>')
        end

        it 'changes inside plus deleted consecutive paragraph, leaving text afterwards with some extra text' do
          doc_a = '<p> Test Paragraph </p>weee<p>More Stuff</p>asd'
          doc_b = '<p>Nothing!</p>weee asd'
          diff = HTMLDiff.diff(doc_a, doc_b)
          expect(diff).to eq('<p><del class="diffmod"> Test Paragraph </del><ins class="diffmod">Nothing!</ins></p>weee<del class="diffmod"><p><del class="diffmod">More Stuff</del></p></del><ins class="diffmod"> </ins>asd')
        end
      end

      it 'wraps inserted tags even with text around' do
        doc_a = '<p>Nothing!</p>weee'
        doc_b = '<p> Test Paragraph </p>weee<p>More Stuff</p>'
        diff = HTMLDiff.diff(doc_a, doc_b)
        expect(diff).to eq('<p><del class="diffmod">Nothing!</del><ins class="diffmod"> Test Paragraph </ins></p>weee<ins class="diffins"><p><ins class="diffins">More Stuff</ins></p></ins>')
      end

      describe 'changing the attributes of tags' do
        it 'ignores a tag with new attributes' do
          doc_a = 'text <p>Nothing!</p> text'
          doc_b = 'text <p style="margin-left: 20px">Nothing!</p> text'
          diff = HTMLDiff.diff(doc_a, doc_b)
          expect(diff).to eq('text <p style="margin-left: 20px">Nothing!</p> text')
        end
      end
    end
  end
end
