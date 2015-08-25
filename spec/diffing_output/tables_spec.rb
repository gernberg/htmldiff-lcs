require File.dirname(__FILE__) + '/../spec_helper'

describe 'HTMLDiff' do
  describe 'diff' do
    describe 'tables' do
      it 'wraps deleted table tags' do
        doc_a = '<p> Test Paragraph </p>
        <p> </p>
        <table><tbody><tr><td>hello</td><td>bye</td></tr></tbody></table>
        <p>&nbsp;</p>
        '
        doc_b = '<p>Nothing!</p>'
        diff = HTMLDiff.diff(doc_a, doc_b)
        expect(diff).to eq('<p><del class="diffmod"> Test Paragraph </del><ins class="diffmod">Nothing!</ins></p><del class="diffdel">
        </del><del class="diffdel"><p><del class="diffdel"> </del></p><del class="diffdel">
        </del><table><tbody><tr><td><del class="diffdel">hello</del></td><td><del class="diffdel">bye</del></td></tr></tbody></table><del class="diffdel">
        </del><p><del class="diffdel">&nbsp;</del></p><del class="diffdel">
        </del></del>')
      end

      it 'should wrap deleted table rows' do
        doc_a = '<p>my table</p>
        <table>
        <tbody>
        <tr><td>hello</td><td>bye</td></tr>
        <tr><td>remove</td><td>me</td></tr>
        </tbody>
        </table>'
        doc_b = '<p>my table</p>
        <table>
        <tbody>
        <tr><td>hello</td><td>bye</td></tr>
        </tbody>
        </table>'
        diff = HTMLDiff.diff(doc_a, doc_b)
        expect(diff).to eq('<p>my table</p>
        <table>
        <tbody>
        <tr><td>hello</td><td>bye</td></tr>
        <del class="diffdel"><tr><td><del class="diffdel">remove</del></td>'\
        '<td><del class="diffdel">me</del></td></tr><del class="diffdel">
        </del></del></tbody>
        </table>')
      end
    end
  end
end
