# encoding: utf-8
require_relative 'htmldiff/diff_builder'
require_relative 'htmldiff/match'
require_relative 'htmldiff/operation'

module HTMLDiff
  def self.diff(old, new, options = {})
    DiffBuilder.new(old, new, options).build
  end
end
