require 'hasher'
class FourGLDB
  class Record
    attr_reader :username, :record, :block_size
    
    def initialize(data, records = nil)
      @block_size, 
      bytes_used, 
      next_record, 
      prev_record, 
      type, 
      locked, 
      readcount, x, 
      @username, x = data[0..55].unpack("qqqqssssa12a4")
      if records
        @record = data[56..-1].unpack("q#{records}")
      else
        @record = data[56..-1].split("\0")
      end
    end
  end
  
  def self.open(file)
    new(file)
  end
  
  def initialize(file)
    @f = File.open(file)
  end
  
  def close
    @f.close
  end
  
  def header
    @header ||= begin
      @f.seek 0x8, IO::SEEK_SET
      keys = [:record_count, :hash_table_size, :hash_start, :min_size, :o_pct]
      values = @f.read(10 * 1.size).unpack("q" * 5)
      values[1] ^= 0x1000000
      Hash[*keys.zip(values).flatten]
    end
  end

  # def record_count
  #  header[:record_count]
  # end
  %w|record_count hash_table_size min_size hash_start|.each do |method|
    define_method(method) do
      header[method.to_sym]
    end
  end
  
  def hash_table
    @hash_table ||= begin
      @f.seek header[:hash_start], IO::SEEK_SET
      length = @f.read(8).unpack("Q")[0]
      @f.seek(-8, IO::SEEK_CUR)
      Record.new(@f.read(length + 56), header[:hash_table_size])
    end
  end
  
  def record_at(offset)
    @f.seek offset, IO::SEEK_SET
    length = @f.read(8).unpack("Q")[0]
    @f.seek(-8, IO::SEEK_CUR)
    Record.new(@f.read(length + 56))
  end
  
  def record_for_key(key)
    record_at(hash_table.record[hasher.hash(key)])
  end
  
  def hasher
    @hasher ||= Hasher.new(header[:hash_table_size])
  end
end