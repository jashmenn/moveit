$:.unshift File.dirname(__FILE__)
require 'spec_helper'
include MoveIt::FileSystem

# requires that you can ssh localhost for this test to pass
# requires "hadoop" binary to be able to connect to an hdfs for hadoop tests to run

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


# ssh_options = {:host => "master0", :user => "root", :keys => ["#{ENV["HOME"]}/.ssh/cloudteam_hadoop_master"]}
# server = MoveIt::FileSystem::POSIX.new(:ssh_options => ssh_options)
# hdfs   = MoveIt::FileSystem::Hdfs.new(:ssh_options => ssh_options)

# files = server.file_list("find /mnt/logfiles/inbox | grep -E (ec2-75-101-174-39|ec2-174-129-82-141)")
# hdfs.mkdir destination rescue nil 

# proxy = MoveIt::FileSystem::Proxy(server, hdfs)

# files.each do |file|
#   proxy.cp file, destination, :verbose => true
# end

  describe "Proxy" do
    describe "copying" do
      # test all supported combinations, eventually it should be all possible combinations
      # [POSIX.new, POSIX.new(:ssh_options => {:host => "localhost"})].each do |source_fs|
      #   [Hdfs.new, Hdfs.new(:ssh_options => {:host => "localhost"})].each do |hdfs|
       [ [POSIX.new, POSIX.new],
         [POSIX.new, Hdfs.new],
         [POSIX.new(:ssh_options => {:host => "localhost"}), Hdfs.new(:ssh_options => {:host => "localhost"})] 
       ].each do |source_fs, dest_fs|

          before(:each) do
            pending unless Hdfs.has_hadoop?
            FileUtils.touch(@dir + "/local/bing")

            @tmp_dir = "moveit_test_folder2"
            dest_fs.rmr(@tmp_dir) rescue nil
            files = dest_fs.ls("")
            files.should_not include(@tmp_dir)
            dest_fs.mkdir(@tmp_dir)
          end

          describe "#cp from #{source_fs} to #{dest_fs}" do
            it "should work" do
              proxy = Proxy.new(source_fs, dest_fs)
              proxy.cp(@dir + "/local/bing", @tmp_dir)
              dest_fs.ls(@tmp_dir).should include("bing")
            end
          end

          after(:each) do
            dest_fs.rmr(@tmp_dir)
          end

        end
    end # local and foreign server

    describe "#same_node?" do
      fs1 = POSIX.new
      fs2 = POSIX.new(:ssh_options => {:host => "localhost"})
      fs3 = Hdfs.new 
      fs4 = Hdfs.new(:ssh_options => {:host => "localhost"})

      tests = [ [fs1, fs3, true],
                [fs1, fs4, false],
                [fs2, fs3, false],
                [fs2, fs4, true] ]

      tests.each do |c|
        it "#{c[0]} and #{c[1]} should be #{c[2]}" do
          Proxy.new(c[0], c[1]).same_node?.should == c[2]
        end
      end

    end
  end

  after(:each) do
    FileUtils.rm_rf(@dir)
  end
end
