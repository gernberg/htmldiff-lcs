module HTMLDiff
  class ListOfWords

    include Enumerable

    def initialize(string)
      if string.respond_to?(:all?) && string.all? { |i| i.is_a?(Word) }
        @words = string
      else
        convert_html_to_list_of_words string.chars
      end
    end

    def each(&block)
      @words.each { |word| block.call(word) }
    end

    def [](index)
      if index.is_a?(Range)
        self.class.new @words[index]
      else
        @words[index]
      end
    end

    def convert_html_to_list_of_words(character_array, use_brackets = false)
      mode = :char
      current_word = Word.new
      @words = []

      while character_array.length > 0
        char = character_array.first

        case mode
          when :tag
            if end_of_tag? char
              current_word << (use_brackets ? ']' : '>')
              @words << current_word
              current_word = Word.new
              if whitespace? char
                mode = :whitespace
              else
                mode = :char
              end
            else
              current_word << char
            end
          when :char
            if start_of_tag? char
              @words << current_word unless current_word.empty?
              current_word = (use_brackets ? Word.new('[') : Word.new('<'))
              mode = :tag
            elsif whitespace? char
              @words << current_word unless current_word.empty?
              current_word = Word.new char
              mode = :whitespace
            elsif char? char
              current_word << char
            else
              @words << current_word unless current_word.empty?
              current_word = Word.new char
            end
          when :whitespace
            if start_of_tag? char
              @words << current_word unless current_word.empty?
              current_word = (use_brackets ? Word.new('[') : Word.new('<'))
              mode = :tag
            elsif whitespace? char
              current_word << char
            else
              @words << current_word unless current_word.empty?
              current_word = Word.new char
              mode = :char
            end
          else
            fail "Unknown mode #{mode.inspect}"
        end

        character_array.shift # Remove this character now we are done
      end
      @words << current_word unless current_word.empty?
    end

    def start_of_tag?(char)
      char == '<'
    end

    def whitespace?(char)
      char =~ /\s/
    end

    def end_of_tag?(char)
      char == '>'
    end

    def char?(char)
      char =~ /[\w\#@]+/i
    end

    def standalone_tag?(item)
      item.downcase =~ /<(img|hr|br)/
    end

    def contains_unclosed_tag?
      tags = 0

      temp_words = @words.dup

      while temp_words.count > 0
        current_word = temp_words.shift
        if current_word.standalone_tag?
          next
        elsif  current_word.opening_tag?
          tags += 1
        elsif  current_word.closing_tag?
          tags -= 1
        end
      end

      tags != 0
    end

    def join(&args)
      @words.join(args)
    end

    def empty?
      count == 0
    end

    def extract_consecutive_words!(&condition)
      index_of_first_tag = nil
      @words.each_with_index do |word, i|
        unless condition.call(word)
          index_of_first_tag = i
          break
        end
      end
      if index_of_first_tag
        @words.slice!(0...index_of_first_tag)
      else
        @words.slice!(0..@words.length)
      end
    end
  end
end
