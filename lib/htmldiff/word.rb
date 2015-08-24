module HTMLDiff
  class Word
    def initialize(word = '')
      @word = word
    end

    def <<(character)
      @word << character
    end

    def empty?
      @word == ''
    end

    def standalone_tag?
      @word.downcase =~ /<(img|hr|br)/
    end

    def iframe_tag?
      (@word[0..7].downcase =~ %r{^<\/?iframe ?})
    end

    def tag?
      opening_tag? || closing_tag? || standalone_tag?
    end

    def opening_tag?
      @word =~ %r{[\s]*<[^\/]{1}[^>]*>\s*$}
    end

    def closing_tag?
      @word =~ %r{^\s*</[^>]+>\s*$}
    end

    def to_s
      @word
    end

    def ==(other)
      @word == other
    end
  end
end
