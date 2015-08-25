# encoding: utf-8
require_relative 'htmldiff/diff_builder'
require_relative 'htmldiff/match'
require_relative 'htmldiff/operation'
require_relative 'htmldiff/word'
require_relative 'htmldiff/list_of_words'
require_relative 'htmldiff/match_finder'

# Main module for namespacing the gem.
module HTMLDiff
  def self.diff(old, new, options = {})
    DiffBuilder.new(old, new, options).build
  end
end
