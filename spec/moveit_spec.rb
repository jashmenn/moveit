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
      before(:each) do 
        @server = server
      end

      it "#{server} should list files" do
        files = @server.file_list("ls -1 #{@dir}/foreign")
        files.size.should == 3
        %w{one two three}.each do |number|
          files.include?(number).should be_true
        end
      end
    end

  end

  after(:each) do
    FileUtils.rm_rf(@dir)
  end
end
