module HTMLDiff
  # This class is responsible for representing one word in one of the HTML
  # strings. Once the HTML has been transformed into words by the ListOfWords
  # class, the diff algorithm then looks for what has changed. The idea is that
  # rather than the standard diff which looks character by character, this will
  # work around the HTML tags so that the output looks only at the text inside
  # them.
  class Word
    def initialize(word = '')
      @word = word
    end

    def <<(character)
      @word << character
    end

    def empty?
      @word.empty?
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

    def block_tag?
      @word =~ /^<div[^<]*class="[^"]*#{block_tag_class}[^"]*"/
    end

    def to_s
      @word
    end

    def ==(other)
      @word == other
    end

    def block_tag_class
      @block_tag_class ||= 'block_tag'
    end
  end
end
