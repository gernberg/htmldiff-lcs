module HTMLDiff
  Match = Struct.new(:start_in_old, :start_in_new, :size) do
    def end_in_old
      start_in_old + size
    end

    def end_in_new
      start_in_new + size
    end
  end

  class Match
    # @!method start_in_old
    # @!method start_in_new
    # @!method size
  end
end
