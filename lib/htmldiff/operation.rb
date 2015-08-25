module HTMLDiff
  # An operation represents one difference between the old HTML and the new
  # HTML. e.g. adding three letters.
  # @param operation can be :insert, :delete or :equal

  Operation = Struct.new(:action, :start_in_old, :end_in_old,
                         :start_in_new, :end_in_new)

  class Operation
    # @!method action
    # @!method start_in_old
    # @!method end_in_old
    # @!method start_in_new
    # @!method end_in_new
  end
end
