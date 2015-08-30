module HTMLDiff
  class ListOfWords

    attr_reader :options

    include Enumerable

    def initialize(string, options = {})
      @options = options
      @block_tag_class = options[:block_tag_class]

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

    def contains_unclosed_tag?
      tags = 0

      temp_words = @words.dup

      while temp_words.count > 0
        current_word = temp_words.shift
        if current_word.standalone_tag?
          next
        elsif current_word.opening_tag?
          tags += 1
        elsif current_word.closing_tag?
          tags -= 1
        end
      end

      tags != 0
    end

    private

    def convert_html_to_list_of_words(character_array)
      @mode = :char
      @current_word = Word.new
      @words = []
      @block_tags = 0

      while character_array.length > 0
        char = character_array.first

        case @mode
          when :tag
            if end_of_tag? char
              @current_word << '>'
              @words << @current_word
              @current_word = Word.new
              if whitespace? char
                @mode = :whitespace
              else
                @mode = :char
              end
            else
              @current_word << char
            end
          when :block_tag
            if start_of_div_tag? character_array
              @block_tags += 1
            elsif end_of_div_tag? character_array
              @block_tags -= 1
              if @block_tags == 0
                @mode = :tag
              end
            end
            @current_word << char
          when :char
            if start_of_tag? char
              @words << @current_word unless @current_word.empty?
              @current_word = Word.new('<')

              if starts_with_block_tag character_array
                @mode = :block_tag
                @block_tags = 1
              else
                @mode = :tag
              end
            elsif whitespace? char
              @words << @current_word unless @current_word.empty?
              @current_word = Word.new char
              @mode = :whitespace
            elsif char? char
              @current_word << char
            else
              @words << @current_word unless @current_word.empty?
              @current_word = Word.new char
            end
          when :whitespace
            if start_of_tag? char
              @words << @current_word unless @current_word.empty?
              @current_word = Word.new('<')
              @mode = :tag
            elsif whitespace? char
              @current_word << char
            else
              @words << @current_word unless @current_word.empty?
              @current_word = Word.new char
              @mode = :char
            end
          else
            fail "Unknown mode #{@mode.inspect}"
        end

        character_array.shift # Remove this character now we are done
      end
      @words << @current_word unless @current_word.empty?
    end

    def start_of_tag?(char)
      char == '<'
    end

    def start_of_div_tag?(character_array)
      character_array.join =~ /^<div/
    end

    def end_of_div_tag?(character_array)
      character_array.join =~ /^<\/div>/
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

    def starts_with_block_tag(character_array)
      Word.new(character_array.join).block_tag?
    end
  end
end
