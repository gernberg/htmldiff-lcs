require 'nokogiri'

module HTMLDiff
  # Main class for building the diff output between two strings. Other classes
  # find out where the differences actually are, then this class turns that into
  # HTML.
  class DiffBuilder
    attr_reader :content

    def initialize(old_version, new_version, options = {})
      @options = default_options.merge options
      @old_words = ListOfWords.new old_version, @options
      @new_words = ListOfWords.new new_version, @options
      @content = []
    end

    def default_options
      {
        block_tag_classes: []
      }
    end

    def build
      perform_operations
      content.join
    end

    # These operations are a list of things that changed between the two
    # versions, which now need to be turned into valid HTML that shows things
    # with ins and del tags.
    def operations
      HTMLDiff::MatchFinder.new(@old_words, @new_words).operations
    end

    def perform_operations
      operations.each { |op| perform_operation(op) }
    end

    def perform_operation(operation)
      send operation.action, operation
    end

    # This is for when a chunk of text has been replaced with a different bit.
    # We want to ignore tags that are the same e.g.
    # '<p>' replaced by
    # '<p class="highlight">'
    # will come back from the diff algorithm as a replacement (tags are treated
    # as words in their entirety), but we don't have any use for seeing this
    # represented visually.
    #
    # @param operation [HTMLDiff::Operation]
    def replace(operation)
      # Special case: a tag has been altered so that an attribute has been
      # added e.g. <p> becomes <p style="margin: 2px"> due to an editor button
      # press. For this, we just show the new version, otherwise it gets messy
      # trying to find the closing tag.
      if operation.same_tag?
        equal(operation)
      else
        delete(operation, 'diffmod')
        insert(operation, 'diffmod')
      end
    end

    # @param operation [HTMLDiff::Operation]
    def insert(operation, tagclass = 'diffins')
      insert_tag('ins', tagclass, operation.new_words)
    end

    # @param operation [HTMLDiff::Operation]
    def delete(operation, tagclass = 'diffdel')
      insert_tag('del', tagclass, operation.old_words)
    end

    # No difference between these parts of the text. No tags to insert, simply
    # copy the matching words from one of the versions.
    #
    # @param operation [HTMLDiff::Operation]
    def equal(operation)
      @content << operation.new_text
    end

    # This method encloses words within a specified tag (ins or del), and adds
    # this into @content, with a twist: if there are words contain tags, it
    # actually creates multiple ins or del, so that they don't include any ins
    # or del tags that are not properly nested. This handles cases like
    # old: '<p>a</p>'
    # new: '<p>ab</p><p>c</p>'
    # diff result: '<p>a<ins>b</ins></p><p><ins>c</ins></p>'
    # This still doesn't guarantee valid HTML (hint: think about diffing a text
    # containing ins or del tags), but handles correctly more cases than the
    # earlier version.
    #
    # P.S.: Spare a thought for people who write HTML browsers. They live in
    # this... every day.
    def insert_tag(tagname, cssclass, words)
      wrapped = false

      loop do
        break if words.empty?

        if words.first.standalone_tag?
          tag_words = words.extract_consecutive_words! do |word|
            word.standalone_tag?
          end
          @content << wrap_text_in_diff_tag(tag_words.join, tagname, cssclass)
        elsif words.first.iframe_tag?
          tag_words = words.extract_consecutive_words! { |word| word.iframe_tag? }
          @content << wrap_text_in_diff_tag(tag_words.join, tagname, cssclass)
        elsif words.first.block_tag?
          tag_words = words.extract_consecutive_words! { |word| word.block_tag? }
          @content << wrap_text_in_diff_tag(tag_words.join, tagname, cssclass)
        elsif words.first.tag?

          # If this chunk of text contains unclosed tags, then wrapping it will
          # cause weirdness. This would be the case if we have e.g. a style
          # applied to a paragraph tag, which will change the opening tag, but
          # not the closing tag.
          #
          #

          if !wrapped && !words.contains_unclosed_tag?
            @content << diff_tag_start(tagname, cssclass)
            wrapped = true
          end
          @content += words.extract_consecutive_words! do |word|
            word.tag? && !word.standalone_tag? && !word.iframe_tag?
          end
        else
          non_tags = words.extract_consecutive_words! do |word|
            (word.standalone_tag? || !word.tag?)
          end
          unless non_tags.join.empty?
            @content << wrap_text_in_diff_tag(non_tags.join, tagname, cssclass)
          end

          break if words.empty?
        end
      end

      @content << diff_tag_end(tagname) if wrapped
    end

    def wrap_text_in_diff_tag(text, tagname, cssclass)
      diff_tag_start(tagname, cssclass) + text + diff_tag_end(tagname)
    end

    def diff_tag_start(tagname, cssclass)
      %(<#{tagname} class="#{cssclass}">)
    end

    def diff_tag_end(tagname)
      %(</#{tagname}>)
    end
  end
end
