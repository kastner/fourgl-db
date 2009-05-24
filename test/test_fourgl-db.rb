require 'test_helper'

def fixture_file(file)
  File.join(File.dirname(__FILE__), 'fixtures', file)
end

class FourglDbTest < Test::Unit::TestCase
  should "be able to open a file" do
    FourGLDB.open(fixture_file("company"))
  end
  
  should "be able to instancate with a file" do
    FourGLDB.new(fixture_file("company"))
  end
  
  should "be able to close a file" do
    f = FourGLDB.open(fixture_file("company"))
    f.close
  end

  context "An open DB's header" do
    setup do
      @f = FourGLDB.open(fixture_file("company"))
    end
    
    should "know it's number of records" do
      @f.record_count.should == 2
    end
    
    should "know it's hash table size" do
      @f.hash_table_size.should == 113
    end
    
    should "know it's minimum record size" do
      @f.min_size.should == 128
    end
    
    should "know where the hash table begins" do
      @f.hash_start.should == 0xd0
    end
  end

  context "An open DB's hash table" do
    setup do
      @f = FourGLDB.open(fixture_file("company"))
    end
    
    should "be a record" do
      @f.hash_table.class.should == FourGLDB::Record
    end
    
    should "know it's username" do
      @f.hash_table.username.should == "APPGENDATA51"
    end
    
    should "have hash_table_size records" do
      @f.hash_table.record.size.should == @f.hash_table_size
    end
    
    should "return the offset of 0x0550 for key '9999'" do
      h = Hasher.new(113)
      @f.hash_table.record[h.hash("9999")].should == 0x0550
    end

    should "return the offset of 0x0490 for key '0'" do
      h = Hasher.new(113)
      @f.hash_table.record[h.hash("0")].should == 0x0490
    end
  end
  
  context "A record from an open DB" do
    setup do
      @record = FourGLDB.open(fixture_file("company")).record_at(0x490)
    end
    
    should "know it's block size" do
      @record.block_size.should == 136
    end
    
    should "have a sane record" do
      @record.record[1].should == "XXXX XXXXXXX TEST COMPANY"
    end
  end
end
