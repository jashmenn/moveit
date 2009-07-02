$:.unshift File.dirname(__FILE__)
require 'spec_helper'

# requires that you can ssh localhost for this test to pass

# connection = MoveIt.ssh_connection(:host => "master0", :key => "#{ENV["HOME"]}/.ssh/cloudteam_hadoop_master")
# server = MoveIt::FileSystem::POSIX.new(:via_ssh => connection)
# hdfs     = MoveIt::FileSystem::Hdfs.new(:via_ssh => connection)
# server.ls("/mnt/logfiles/inbox")
# server.file_list("find /mnt/logfiles/inbox | grep 2009")

describe "Moveit" do
  before(:each) do 
    @dir = File.expand_path(FIXTURES_DIR + "/ssh")
    FileUtils.mkdir_p(@dir + "/foreign")
    FileUtils.mkdir_p(@dir + "/local")

    %w{one two three}.each do |number|
      FileUtils.touch("#{@dir}/foreign/#{number}")
    end
  end

  describe "local & ssh actions" do
    [MoveIt::FileSystem::POSIX.new, MoveIt::FileSystem::POSIX.new(:ssh_options => {:host => "localhost"})].each do |server|
      describe "listing files" do
        # sorry this is ugly, but its DRY and they're testing the same thing
        [[:file_list, lambda{|s,d| s.file_list("ls -1 #{d}")}], [:ls, lambda{|s,d| s.ls(d)}]].each do |name, prok|
          it "#{server} ##{name}" do
            files = prok.call(server, "#{@dir}/foreign")
            files.size.should == 3
            %w{one two three}.each do |number|
              files.include?(number).should be_true
            end
          end
        end
      end # end listing files

    end # end local and ssh
  end 

  describe "hdfs actions" do
    before(:each) do
      pending unless MoveIt::FileSystem::Hdfs.has_hadoop?
      @server = MoveIt::FileSystem::Hdfs.new
    end

    describe "#ls" do
      it "should list directories" do
        files = @server.ls("")
        files.should have_at_least(1).file
      end
    end
    describe "#mkdir and #rmr" do
      it "should make a directory" do
        dir = "moveit_test_folder"
        @server.rmr(dir) rescue nil
        files = @server.ls("")
        files.should_not include(dir)
        @server.mkdir(dir)
        @server.ls("").should include(dir)
        @server.rmr(dir)
      end
    end
  end

  after(:each) do
    FileUtils.rm_rf(@dir)
  end
end
