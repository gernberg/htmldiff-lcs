require 'diff/lcs'

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
    end

    def operations
      locate_matching_blocks
      define_operations
      @operations
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
      @matching_blocks = matching_sdiff_segments.map do |segment|
        create_match_from(segment)
      end

      # an empty match at the end forces the loop to make operations to handle
      # the unmatched tails I'm sure it can be done more gracefully, but not at
      # 23:52
      @matching_blocks << HTMLDiff::Match.new(@old_words.size,
                                              @new_words.size, 0)
    end
    
    def matching_sdiff_segments
      @matching_sdiff_segments ||= sdiff_sliced.select { |diffs| diffs.first.action == '=' }
    end
    
    def sdiff
      @sdiff ||= Diff::LCS.sdiff(@old_words, @new_words)
    end
    
    def sdiff_sliced
      @sdiff_sliced ||= begin
        # Writing out the JRuby implementation of slice_when here, essentially, for backwards
        # compat with older Ruby versions
        result = []
        ary = nil
        last_after = nil
        sdiff.each_cons(2) do |before, after|
          last_after = after
          match = (before.action != after.action)
          
          ary ||= []
          ary << before
          if match
            result << ary
            ary = []
          end
        end
        
        unless ary.nil?
          ary << last_after
          result << ary
        end
        
        result
      end
    end
    
    def create_match_from(context_change_segment)
      HTMLDiff::Match.new(
        context_change_segment.first.old_position, 
        context_change_segment.first.new_position, 
        context_change_segment.size
      )
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
