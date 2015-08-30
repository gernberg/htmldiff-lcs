module HTMLDiff
  # This class is responsible for comparing the list of old and new words and
  # coming up with a list of insert, delete and replace operations, which the
  # builder will turn into presentable HTML output.
  class MatchFinder
    attr_accessor :old_words, :new_words

    def initialize(old_words, new_words)
      @old_words = old_words
      @new_words = new_words
      @matching_blocks = []
      @new_word_indices = Hash.new { |h, word| h[word] = [] }
    end

    def operations
      index_new_words
      locate_matching_blocks
      define_operations
      @operations
    end

    # This leaves us with { first => [1], 'second' => [2, 3] } to tell us where
    # in @new_words each word appears.
    #
    # %w(ant bat cat ant) => { ant => [0, 3], bat => 1, cat => 2}
    def index_new_words
      @new_words.each_with_index { |word, i| @new_word_indices[word.to_s] << i }
    end

    # This gets an array of the sections of the two strings that match, then
    # returns an array of operations that need to be performed in order to
    # build the HTML output that will show the diff.
    #
    # The method is to move along the old and new strings, marking the bits
    # between the matched portions as insert, delete or replace by creating an
    # instance of Operation for each one.
    def define_operations
      # Starting point of potential difference (end of last match, or start
      # of string)
      @position_in_old = @position_in_new = 0
      @operations = []

      @matching_blocks.each do |match|
        create_operation_from(match)
      end
    end

    # The returned array is of matches in the order in which they appear in the
    # strings. Each array item is an instance of Match, which contains the
    # start index of the match in @old_words, the start index in @new_words,
    # and the length in number of words.
    def locate_matching_blocks
      recursively_find_matching_blocks_in_range(0, @old_words.count,
                                                0, @new_words.count)

      # an empty match at the end forces the loop to make operations to handle
      # the unmatched tails I'm sure it can be done more gracefully, but not at
      # 23:52
      @matching_blocks << HTMLDiff::Match.new(@old_words.count,
                                              @new_words.count, 0)
    end

    # The first time this is called, it checks the whole of the two strings and
    # finds the longest match between them.
    # It then recursively checks the gaps that are left either side of the
    # longest match, until there are no smaller matches.
    def recursively_find_matching_blocks_in_range(start_in_old,
                                                  end_in_old,
                                                  start_in_new,
                                                  end_in_new)
      # Longest match in the given range.
      longest_match = find_longest_match_between_ranges(start_in_old,
                                                        end_in_old,
                                                        start_in_new,
                                                        end_in_new)
      return unless longest_match.size > 0


      if start_in_old < longest_match.start_in_old &&
         start_in_new < longest_match.start_in_new
        # The match is not at the start of either range.
        # Search the gap before the longest match and add any smaller matches
        # from there.
        recursively_find_matching_blocks_in_range(start_in_old,
                                                  longest_match.start_in_old,
                                                  start_in_new,
                                                  longest_match.start_in_new)
      end

      # Add the longest match
      @matching_blocks << longest_match

      if longest_match.end_in_old < end_in_old &&
         longest_match.end_in_new < end_in_new
        # The match is not at the end of either range.
        # Search the gap after the longest match and add any smaller matches
        # from there
        recursively_find_matching_blocks_in_range(longest_match.end_in_old,
                                                  end_in_old,
                                                  longest_match.end_in_new,
                                                  end_in_new)
      end
    end

    # This will find the longest matching set of words when comparing the given
    # ranges in @old_words and @new_words. This function is used recursively, so
    # the variables should not be class variables.
    #
    # @return [HTMLDiff::Match]
    def find_longest_match_between_ranges(start_in_old, end_in_old,
                                          start_in_new, end_in_new)
      best_match = HTMLDiff::Match.new 0, 0, 0
      matches = []

      # A match is a string of words which is in both @old_words and @new words
      # at a certain position. Keep track of the length of matches starting at
      # each index position in @new_words. e.g. if the match length at index
      # 4 = 3, then that means that the fourth word in @new_words is the
      # end of a 3-word-long match.
      #
      # If there are two matches of the same size, it'll get the first one.
      match_lengths_at_previous_index_positions_in_new = Hash.new { |h, index| h[index] = 0 }

      # Start at the beginning position in @old_words and move forwards one
      # word at a time.
      start_in_old.upto(end_in_old - 1) do |index_in_old|
        # This will store the match lengths for all words so far up to the
        # current word. Just looking at this word, the lengths will all be 1,
        # so we check the match length for the preceding word in @new_words.
        # If that is non-zero, it means that a previous match happened up to
        # this point.
        #
        # If the current word is a continuation of a match, then we will
        # increment the match length and store it for the current index
        # position in @new_words. We replace the old hash because then we
        # ignore the previous match that has now been extended and any that have
        # stopped.
        match_lengths_at_current_index_positions_in_new = Hash.new { |h, index| h[index] = 0 }

        # Take the word which is at this position in @old_words,
        # then for each position it occurs in within @new_words...
        current_word_in_old = @old_words[index_in_old].to_s
        @new_word_indices[current_word_in_old].each do |index_in_new|
          # Skip if this position is before the start of the range we're
          # checking.
          next if index_in_new < start_in_new
          # Since the indices in @new_words start at the earliest occurrence
          # and are in order, if we are now after the end of the range we are
          # checking, then all later occurrences can be ignored.
          break if index_in_new >= end_in_new

          # Add 1 to the length of the match we have for the previous word
          # position in @new_words. i.e. we are moving along @old words,
          # ticking off the words in @new_words as we go.
          #
          # Will be zero if the previous word in @new_words has not been marked
          # as a match.

          new_match_length = match_lengths_at_previous_index_positions_in_new[index_in_new - 1] + 1
          match_lengths_at_current_index_positions_in_new[index_in_new] = new_match_length

          # Keep track of the longest match so we can return it.
          if new_match_length > best_match.size
            start_of_best_match_in_old = index_in_old - new_match_length + 1
            start_of_best_match_in_new = index_in_new - new_match_length + 1

            best_match = HTMLDiff::Match.new(start_of_best_match_in_old,
                                             start_of_best_match_in_new,
                                             new_match_length)

            # best_match = HTMLDiff::NewMatch.new(index_in_old - new_match_length + 1, index_in_old,
            #                                     index_in_new - new_match_length + 1, index_in_new
            #                                  )
          end
        end

        # We have now added the current word to all the matches we had so far,
        # making some of them longer by 1. Any matches that are shorter (didn't
        # have the current word as the next word) are discarded.
        match_lengths_at_previous_index_positions_in_new = match_lengths_at_current_index_positions_in_new
      end

      best_match
    end

    # @param [HTMLDiff::Match] match
    def create_operation_from(match)
      # We have a problem with single space matches found in between words
      # which are otherwise different. If we find a match that is just a
      # single space, then we should ignore it so that the # changes before
      # and after it merge together.
      old_text = @old_words[match.start_in_old...match.end_in_old].join
      new_text = @new_words[match.start_in_new...match.end_in_new].join
      return if old_text == ' ' && old_text == new_text

      match_starts_at_current_position_in_old = (@position_in_old == match.start_in_old)
      match_starts_at_current_position_in_new = (@position_in_new == match.start_in_new)

      # Based on where the match starts and ends, work out what the preceding
      # non-matching bit represents.
      action_upto_match_positions =
        case [match_starts_at_current_position_in_old,
              match_starts_at_current_position_in_new]
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

      # This operation will add the <ins> or <del> tag, plus the content
      # that has changed.
      if action_upto_match_positions != :none
        operation_upto_match_positions =
          Operation.new(action_upto_match_positions,
                        @old_words[@position_in_old...match.start_in_old],
                        @new_words[@position_in_new...match.start_in_new]
          )
        @operations << operation_upto_match_positions
      end
      if match.size != 0
        match_operation = Operation.new(:equal,
                                        @old_words[match.start_in_old...match.end_in_old],
                                        @new_words[match.start_in_new...match.end_in_new]
        )
        @operations << match_operation
      end

      # Move to the end of the match (start of next difference).
      @position_in_old = match.end_in_old
      @position_in_new = match.end_in_new
    end
  end
end
