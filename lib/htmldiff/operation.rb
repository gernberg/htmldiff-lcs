module HTMLDiff
  # An operation represents one differece between the old HTML and the new
  # HTML. e.g. adding three letters.
  # @param operation can be :insert, :delete or :equal
  Operation = Struct.new(:action, :start_in_old, :end_in_old,
                         :start_in_new, :end_in_new)
end