require 'spec_helper'

describe HTMLDiff::Operation do
  describe 'same_tag?' do
    let(:old_words) { HTMLDiff::ListOfWords.new old_tag }
    let(:new_words) { HTMLDiff::ListOfWords.new new_tag }
    let(:operation) { HTMLDiff::Operation.new :equal, old_words, new_words }

    context 'with identical tags' do
      let(:old_tag) { '<p>' }
      let(:new_tag) { '<p>' }

      it 'returns true for identical simple tags' do
        expect(operation.same_tag?).to be_true
      end
    end

    context 'with the same tag that has a new attribute' do
      let(:old_tag) { '<p>' }
      let(:new_tag) { '<p style="margin: 2px;">' }

      it 'returns true for one simple and one complex tag' do
        expect(operation.same_tag?).to be_true
      end
    end

    context 'with two different tags' do
      let(:old_tag) { '<p>' }
      let(:new_tag) { '<b>' }

      it 'returns false for non matching simple tags' do
        expect(operation.same_tag?).to be_false
      end
    end

    context 'with two identical bits of text' do
      let(:old_tag) { 'blah' }
      let(:new_tag) { 'blah' }

      it 'should return false for random text' do
        expect(operation.same_tag?).to be_false
      end
    end
  end
end
