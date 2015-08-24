require 'nokogiri'

module HTMLDiff
  # Main class for building the diff output between two strings
  class DiffBuilder
    attr_reader :content

    def initialize(old_version, new_version, options = {})
      @old_words = ListOfWords.new old_version
      @new_words = ListOfWords.new new_version
      @options = options
      @content = []
    end

    def build
      perform_operations
      content.join
    end

    def operations
      HTMLDiff::MatchFinder.new(@old_words, @new_words).operations
    end

    def perform_operations
      operations.each { |op| perform_operation(op) }
    end

    VALID_METHODS = [:replace, :insert, :delete, :equal]

    def perform_operation(operation)
      @operation = operation
      send operation.action, operation
    end

    # @param [HTMLDiff::Operation] operation
    def replace(operation)
      # Special case: a tag has been altered so that an attribute has been
      # added e.g. <p> becomes <p style="margin: 2px"> due to an editor button
      # press. For this, we just show the new version, otherwise it gets messy
      # trying to find the closing tag.
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
      # no tags to insert, simply copy the matching words from one of the
      # versions
      @content += @new_words[operation.start_in_new...operation.end_in_new].to_a
    end

    # Ignores any attributes and tells us if the tag is the same e.g. <p> and
    # <p style="margin: 2px;">
    def same_tag?(first_tag, second_tag)
      pattern = /<([^>\s]+)[\s>]{1}.*/
      first_tagname = pattern.match(first_tag) # nil means they are not tags
      first_tagname = first_tagname[1] if first_tagname

      second_tagname = pattern.match(second_tag)
      second_tagname = second_tagname[1] if second_tagname

      first_tagname && (first_tagname == second_tagname)
    end

    # This method encloses words within a specified tag (ins or del), and adds
    # this into @content, with a twist: if there are words contain tags, it
    # actually creates multiple ins or del, so that they don't include any ins
    # or del. This handles cases like
    # old: '<p>a</p>'
    # new: '<p>ab</p><p>c</p>'
    # diff result: '<p>a<ins>b</ins></p><p><ins>c</ins></p>'
    # this still doesn't guarantee valid HTML (hint: think about diffing a text
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
          img_tag = words.extract_consecutive_words! { |word| word.standalone_tag? }
          @content << wrap_text(img_tag, tagname, cssclass)
        elsif words.first.iframe_tag?
          img_tag = words.extract_consecutive_words! { |word| word.iframe_tag? }
          @content << wrap_text(img_tag, tagname, cssclass)
        elsif words.first.tag?

          # If this chunk of text contains orphaned tags, then wrapping it will
          # cause weirdness. This would be the case if we have e.g. a style
          # applied to a paragraph tag, which will change the opening tag, but
          # not the closing tag.
          #
          # If we do decide to wrap the whole

          if !wrapped && !words.contains_unclosed_tag?
            @content << wrap_start(tagname, cssclass)
            wrapped = true
          end
          @content += words.extract_consecutive_words! { |word| word.tag? && !word.standalone_tag? && !word.iframe_tag? }
        else
          non_tags = words.extract_consecutive_words! { |word| (word.standalone_tag? || !word.tag?) }
          @content << wrap_text(non_tags.join, tagname, cssclass) unless non_tags.join.empty?

          break if words.empty?
        end
      end

      @content << wrap_end(tagname) if wrapped
    end

    def wrap_text(text, tagname, cssclass)
      [wrap_start(tagname, cssclass),
       text,
       wrap_end(tagname)
      ].join
    end

    def wrap_start(tagname, cssclass)
      %(<#{tagname} class="#{cssclass}">)
    end

    def wrap_end(tagname)
      %(</#{tagname}>)
    end
  end
end
