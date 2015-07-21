module HTMLDiff
  # Main class for building the diff output between two strings
  class DiffBuilder
    def initialize(old_version, new_version, options = {})
      @old_version, @new_version = old_version, new_version
      @content = []
      @unclosed_tags = [] # This keeps count of any HTML tags that have attributes changed, which makes only one of them show up.
    end

    def build
      split_inputs_to_words
      index_new_words
      operations.each { |op| perform_operation(op) }
      @content.join
    end

    def split_inputs_to_words
      @old_words = convert_html_to_list_of_words(explode(@old_version))
      @new_words = convert_html_to_list_of_words(explode(@new_version))
    end

    # This leaves us with { first => [1], 'second' => [2, 3] } to tell us where in @new_words each word appears.
    def index_new_words
      @word_indices = Hash.new { |h, word| h[word] = [] }
      @new_words.each_with_index { |word, i| @word_indices[word] << i }
    end

    # This gets an array of the sections of the two strings that match, then returns an array of operations
    # that need to be performed in order to build the HTML output that will show the diff.
    #
    # The method is to move along the old and new strings, marking the bits between the matched portions as
    # insert, delete or replace by creating an instance of Operation for each one.
    def operations
      position_in_old = position_in_new = 0 # Starting point of potential difference (end of last match, or start of string)
      operations = []

      matches = matching_blocks
      # an empty match at the end forces the loop below to handle the unmatched tails
      # I'm sure it can be done more gracefully, but not at 23:52
      matches << Match.new(@old_words.length, @new_words.length, 0)

      matches.each_with_index do |match, i|

        # We have a problem with single space matches found in between words which are otherwise different.
        # If we find a match that is just a single space, then we should ignore it so that the
        # changes before and after it merge together.
        old_text = @old_words[match.start_in_old...match.end_in_old].join
        new_text = @new_words[match.start_in_new...match.end_in_new].join
        if old_text == ' ' && old_text == new_text
          next
        end

        match_starts_at_current_position_in_old = (position_in_old == match.start_in_old)
        match_starts_at_current_position_in_new = (position_in_new == match.start_in_new)

        # Based on where the match starts and ends, work out what the preceding non-matching bit represents.
        action_upto_match_positions =
          case [match_starts_at_current_position_in_old, match_starts_at_current_position_in_new]
            when [false, false]
              :replace
            when [true, false]
              :insert
            when [false, true]
              :delete
            else
              # this happens if the first few words are same in both versions
              :none
          end

        # This operation will add the <ins> or <del> tag, plus the content that has changed.
        if action_upto_match_positions != :none
          operation_upto_match_positions =
            Operation.new(action_upto_match_positions,
                          position_in_old, match.start_in_old,
                          position_in_new, match.start_in_new)
          operations << operation_upto_match_positions
        end
        if match.size != 0
          match_operation = Operation.new(:equal,
                                          match.start_in_old, match.end_in_old,
                                          match.start_in_new, match.end_in_new)
          operations << match_operation
        end

        # Move to the end of the match (start of next difference).
        position_in_old = match.end_in_old
        position_in_new = match.end_in_new
      end

      operations
    end

    # The returned array is of matches in the order in which they appear in the strings. Each array item
    # is an instance of Match, which contains the start index of the match in @old_words, the start index
    # in @new_words, and the length in number of words.
    def matching_blocks
      matching_blocks = []
      recursively_find_matching_blocks(0, @old_words.size, 0, @new_words.size, matching_blocks)
      matching_blocks
    end

    # The first time this is called, it checks the whole of the two strings. It then recursively checks the
    # gaps that are left either side of the longest match, until there are no smaller matches.
    def recursively_find_matching_blocks(start_in_old, end_in_old, start_in_new, end_in_new, matching_blocks)
      match = find_match(start_in_old, end_in_old, start_in_new, end_in_new) # Longest match in the given range.
      if match
        if start_in_old < match.start_in_old and start_in_new < match.start_in_new # The match is not at the start of either range
          # Search the gap before the longest match and add any smaller matches from there.
          recursively_find_matching_blocks(start_in_old, match.start_in_old, start_in_new, match.start_in_new, matching_blocks)
        end
        # Add the longest match
        matching_blocks << match
        if match.end_in_old < end_in_old and match.end_in_new < end_in_new # The match is not at the end of either range.
          # Search the gap after the longest match and add any smaller matches from there
          recursively_find_matching_blocks(match.end_in_old, end_in_old, match.end_in_new, end_in_new, matching_blocks)
        end
      end
    end

    # This will find the longest matching set of words when comparing the given ranges in @old_words and
    # @new_words.
    def find_match(start_in_old, end_in_old, start_in_new, end_in_new)

      start_of_best_match_in_old = start_in_old
      start_of_best_match_in_new = start_in_new
      best_match_size = 0

      # A match is a string of words which is in both @old_words and @new words at a certain position.
      # Keep track of the length of matches starting at each index position in @new_words.
      # e.g. if the match length at index 4 = 3, then that means that the fourth word in @new_words is the
      # end of a 3-word-long match.
      #
      # If there are two matches of the same size, it'll get the first one.
      match_length_at = Hash.new { |h, index| h[index] = 0 }

      # Start at the beginning position in @old_words and move forwards one word at a time
      start_in_old.upto(end_in_old - 1) do |index_in_old|

        # This will store the match lengths for all words so far up to the current word.
        # Just looking at this word, the lengths will all be 1, so we check the match length
        # for the preceding word in @new_words. If that is non-zero, it means that a previous match
        # happened up to this point.
        #
        # If the current word is a continuation of a match, then we will increment the match length and store
        # it for the current index position in @new_words.
        new_match_length_at = Hash.new { |h, index| h[index] = 0 }

        # Take the word which is at this position in @old_words,
        # then for each position it occurs in within @new_words...
        @word_indices[@old_words[index_in_old]].each do |index_in_new|
          next if index_in_new < start_in_new # Skip if we've moved past this position in @new_words already.
          break if index_in_new >= end_in_new # Stop at the end position we are checking up to in @new_words

          # Add 1 to the length of the match we have for the previous word position in @new_words.
          # i.e. we are moving along @old words, ticking off letters in @new_words as we go.
          new_match_length = match_length_at[index_in_new - 1] + 1 # Will be zero if the previous word in @new_words has not been marked as a match
          new_match_length_at[index_in_new] = new_match_length

          # Keep track of the longest match so we can return it.
          if new_match_length > best_match_size
            start_of_best_match_in_old = index_in_old - new_match_length + 1
            start_of_best_match_in_new = index_in_new - new_match_length + 1
            best_match_size = new_match_length
          end
        end

        # We have now added the current word to all the matches we had so far, making some of them longer by 1.
        # Any matches that are shorter (didn't have the current word as the next word) are discarded.
        match_length_at = new_match_length_at
      end

      (best_match_size != 0 ? Match.new(start_of_best_match_in_old, start_of_best_match_in_new, best_match_size) : nil)
    end

    def add_matching_words_left(match_in_old, match_in_new, match_size, start_in_old, start_in_new)
      while match_in_old > start_in_old and
        match_in_new > start_in_new and
        @old_words[match_in_old - 1] == @new_words[match_in_new - 1]
        match_in_old -= 1
        match_in_new -= 1
        match_size += 1
      end
      [match_in_old, match_in_new, match_size]
    end

    def add_matching_words_right(match_in_old, match_in_new, match_size, end_in_old, end_in_new)
      while match_in_old + match_size < end_in_old and
        match_in_new + match_size < end_in_new and
        @old_words[match_in_old + match_size] == @new_words[match_in_new + match_size]
        match_size += 1
      end
      [match_in_old, match_in_new, match_size]
    end

    VALID_METHODS = [:replace, :insert, :delete, :equal]

    def perform_operation(operation)
      @operation = operation
      self.send operation.action, operation
    end

    def replace(operation)
      # Special case: a tag has been altered so that an attribute has been added e.g.
      # <p> becomes <p style="margin: 2px"> due to an editor button press. For this, we just
      # Show the new version, otherwise it gets messy trying to find the closing tag.
      old_text = @old_words[operation.start_in_old...operation.end_in_old].join
      new_text = @new_words[operation.start_in_new...operation.end_in_new].join
      if same_tag?(old_text, new_text)
        equal(operation)
      else
        delete(operation, 'diffmod')
        insert(operation, 'diffmod')
      end
    end

    # @param operation [HTMLDiff::Operation]
    def insert(operation, tagclass = 'diffins')
      insert_tag('ins', tagclass, @new_words[operation.start_in_new...operation.end_in_new])
    end

    def delete(operation, tagclass = 'diffdel')
      insert_tag('del', tagclass, @old_words[operation.start_in_old...operation.end_in_old])
    end

    def equal(operation)
      # no tags to insert, simply copy the matching words from one of the versions
      @content += @new_words[operation.start_in_new...operation.end_in_new]
    end

    def opening_tag?(item)
      item =~ /[\s]*<[^\/]{1}[^>]*>\s*$/
    end

    def closing_tag?(item)
      item =~ %r!^\s*</[^>]+>\s*$!
    end

    def standalone_tag?(item)
      item.downcase =~ /<(img|hr|br)/
    end

    # Ignores any attributes and tells us if the tag is the same e.g. <p> and <p style="margin: 2px;">
    def same_tag?(first_tag, second_tag)
      pattern = /<([^>\s]+)[\s>]{1}.*/
      first_tagname = pattern.match(first_tag) # nil means they are not tags
      first_tagname = first_tagname[1] if first_tagname

      second_tagname = pattern.match(second_tag)
      second_tagname = second_tagname[1] if second_tagname

      first_tagname && (first_tagname == second_tagname)
    end

    def tag?(item)
      opening_tag?(item) or closing_tag?(item) or standalone_tag?(item)
    end

    def iframe_tag?(item)
      (item[0..7].downcase =~ /^<\/?iframe ?/)
    end

    def extract_consecutive_words(words, &condition)
      index_of_first_tag = nil
      words.each_with_index do |word, i|
        if !condition.call(word)
          index_of_first_tag = i
          break
        end
      end
      if index_of_first_tag
        return words.slice!(0...index_of_first_tag)
      else
        return words.slice!(0..words.length)
      end
    end

    # This method encloses words within a specified tag (ins or del), and adds this into @content,
    # with a twist: if there are words contain tags, it actually creates multiple ins or del,
    # so that they don't include any ins or del. This handles cases like
    # old: '<p>a</p>'
    # new: '<p>ab</p><p>c</p>'
    # diff result: '<p>a<ins>b</ins></p><p><ins>c</ins></p>'
    # this still doesn't guarantee valid HTML (hint: think about diffing a text containing ins or
    # del tags), but handles correctly more cases than the earlier version.
    #
    # P.S.: Spare a thought for people who write HTML browsers. They live in this... every day.

    def insert_tag(tagname, cssclass, words)
      wrapped = false

      loop do

        break if words.empty?

        if standalone_tag?(words.first)
          img_tag = extract_consecutive_words(words) { |word| standalone_tag?(word) }
          @content << wrap_text(img_tag, tagname, cssclass)
        elsif iframe_tag?(words.first)
          img_tag = extract_consecutive_words(words) { |word| iframe_tag?(word) }
          @content << wrap_text(img_tag, tagname, cssclass)
        elsif tag?(words.first)

          # If this chunk of text contains orphaned tags, then wrapping it will cause weirdness.
          # This would be the case if we have e.g. a style applied to a paragraph tag, which will
          # change the opening tag, but not the closing tag.
          #
          # If we do decide to wrap the whole

          if !wrapped && !contains_unclosed_tag?(words.join)
            @content << wrap_start(tagname, cssclass)
            wrapped = true
          end
          @content += extract_consecutive_words(words) { |word| tag?(word) && !standalone_tag?(word) && !iframe_tag?(word) }
        else
          non_tags = extract_consecutive_words(words) { |word| (standalone_tag?(word)) || (!tag?(word)) }
          @content << wrap_text(non_tags.join, tagname, cssclass) unless non_tags.join.empty?

          break if words.empty?
        end
      end

      if wrapped
        @content << wrap_end(tagname)
      end
    end

    def wrap_text(text, tagname, cssclass)
      [wrap_start(tagname, cssclass),
       text,
       wrap_end(tagname)
      ].join
    end

    def wrap_start(tagname, cssclass)
      %|<#{tagname} class="#{cssclass}">|
    end

    def wrap_end(tagname)
      %|</#{tagname}>|
    end

    def explode(sequence)
      sequence.is_a?(String) ? sequence.chars : sequence
    end

    def end_of_tag?(char)
      char == '>'
    end

    def start_of_tag?(char)
      char == '<'
    end

    def whitespace?(char)
      char =~ /\s/
    end

    def char?(char)
      char =~ /[\w\#@]+/i
    end

    def convert_html_to_list_of_words(x, use_brackets = false)
      mode = :char
      current_word = ''
      words = []

      explode(x).each do |char|
        case mode
          when :tag
            if end_of_tag? char
              current_word << (use_brackets ? ']' : '>')
              words << current_word
              current_word = ''
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
              words << current_word unless current_word.empty?
              current_word = (use_brackets ? '[' : '<')
              mode = :tag
            elsif whitespace? char
              words << current_word unless current_word.empty?
              current_word = char
              mode = :whitespace
            elsif char? char
              current_word << char
            else
              words << current_word unless current_word.empty?
              current_word = char
            end
          when :whitespace
            if start_of_tag? char
              words << current_word unless current_word.empty?
              current_word = (use_brackets ? '[' : '<')
              mode = :tag
            elsif whitespace? char
              current_word << char
            else
              words << current_word unless current_word.empty?
              current_word = char
              mode = :char
            end
          else
            raise "Unknown mode #{mode.inspect}"
        end
      end
      words << current_word unless current_word.empty?
      words
    end

    # This is supposed to catch string with a single unclosed tag, but multi-line things seem to be breaking it.
    def unclosed_tag_regex
      /<(\w+)[^>]*(?<!\/)>((?!<\/\1>).)*$/
    end

    # Tells us if we have an unmatched HTML tag e.g. <p> has changed to <p style="margin-left: 20px;">
    # Only works with single tags, but its unlikely to be a problem.
    def contains_unclosed_tag?(string_to_check)
      bits_of_string = convert_html_to_list_of_words(explode(string_to_check))
      tags = 0

      while bits_of_string.size > 0
        current_bit = bits_of_string.shift
        if standalone_tag? current_bit
          next
        elsif opening_tag? current_bit
          tags += 1
        elsif closing_tag? current_bit
          tags -= 1
        end
      end

      tags != 0
    end

    def unclosed_tag(string_to_check)
      string_to_check.scan(unclosed_tag_regex).first.first
    end
  end
end