module VirtFS::Ext3
  class BlockPointersPath
    DIRECT_SIZE           = 12
    SINGLE_INDIRECT_INDEX = 12
    DOUBLE_INDIRECT_INDEX = 13
    TRIPLE_INDIRECT_INDEX = 14

    INDEX_TYPES = [:direct, :single_indirect, :double_indirect, :triple_indirect]

    attr_reader :num_indirects, :path, :path_index, :block

    def initialize(num_indirects, block = 0)
      @num_indirects = num_indirects
      @single_indirect_size = @num_indirects
      @double_indirect_size = @num_indirects**2
      @triple_indirect_size = @num_indirects**3

      @single_indirect_base_size = DIRECT_SIZE
      @double_indirect_base_size = DIRECT_SIZE + @single_indirect_size
      @triple_indirect_base_size = DIRECT_SIZE + @single_indirect_size + @double_indirect_size

      self.block = block
    end

    def direct_index;          @path[0]; end

    def single_indirect_index; @path[1]; end

    def double_indirect_index; @path[2]; end

    def triple_indirect_index; @path[3]; end

    def index_type; INDEX_TYPES[@path_index]; end

    def direct?;          @path_index == 0; end

    def single_indirect?; @path_index == 1; end

    def double_indirect?; @path_index == 2; end

    def triple_indirect?; @path_index == 3; end

    def block=(value)
      block_to_path(value)
      @block = value
    end

    def succ!
      succ_index(@path_index)
      @block += 1
      self
    end

    def to_s
      @path.inspect
    end

    def to_a
      @path.dup
    end

    protected

    def succ_index(index)
      val = (@path[index] += 1)
      if index == 0
        raise RangeError if val > TRIPLE_INDIRECT_INDEX

        if val >= SINGLE_INDIRECT_INDEX
          @path_index += 1
          @path[@path_index] = 0
        end
      elsif val == @num_indirects
        @path[index] = 0
        succ_index(index - 1)
      end
    end

    def block_to_path(blk)
      raise ArgumentError, "block must be greater than or equal to 0" if blk < 0
      @path = [nil, nil, nil, nil]

      if blk < DIRECT_SIZE
        @path[0] = blk
        @path_index = 0
        return
      end
      blk -= DIRECT_SIZE

      if blk < @single_indirect_size
        @path[0] = SINGLE_INDIRECT_INDEX
        @path[1] = blk
        @path_index = 1
        return
      end
      blk -= @single_indirect_size

      if blk < @double_indirect_size
        @path[0] = DOUBLE_INDIRECT_INDEX
        @path[1], @path[2] = blk.divmod(@single_indirect_size)
        @path_index = 2
        return
      end
      blk -= @double_indirect_size

      if blk < @triple_indirect_size
        @path[0] = TRIPLE_INDIRECT_INDEX
        @path[1], blk = blk.divmod(@double_indirect_size)
        @path[2], @path[3] = blk.divmod(@single_indirect_size)
        @path_index = 3
        return
      end

      raise ArgumentError, "block outside valid range"
    end

    def path_to_block
      case @path_index
      when 0
        direct_index
      when 1
        @single_indirect_base_size + single_indirect_index
      when 2
        @double_indirect_base_size + (single_indirect_index * @single_indirect_size) + double_indirect_index
      when 3
        @triple_indirect_base_size + (single_indirect_index * @double_indirect_size) + (double_indirect_index * @single_indirect_size) + triple_indirect_index
      end
    end
  end # class BlockPointersPath
end # module VirtFS::Ext3
