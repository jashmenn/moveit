require 'rubygems'
require "has_logger"
require "net/ssh"

# FileUtils for the rest of your storage locations (ssh, s3, hdfs, etc)
module MoveIt
  module FileSystem
    class Base
      include HasLogger

      def cleanup
      end
    end

    class POSIX < Base
      attr_reader :actor

      def initialize(opts={})
        @actor = Actor.new(opts)
      end

      def ls(dir)
        file_list("ls -1 #{dir}")
      end

      def file_list(cmd)
        output = @actor.exec!(cmd)
        output.split("\n")
      end

      def cleanup
        @actor.cleanup
      end

      def to_s
        "#<#{self.class.to_s}:#{self.object_id}, %s>" % [@actor.using_ssh? ? @actor.ssh_options.inspect : "local"]
      end
    end

    class Hdfs < POSIX # hmm
      def self.has_hadoop?
        `which hadoop`
        $? == 0 ? true : false
      end

      # direct mapping to hadoop fs cmds
      %w{ls mkdir rm rmr}.each do |cmd|
        class_eval <<-EOE
          def #{cmd}(path)
            hadoop_fs("-#{cmd} \#{path}")
          end
        EOE
      end

      # cp is a cp local to the hdfs, potentially confusing in light of the Proxy, but should be supported
      # def cp(from, destination)
      # end

      def hadoop_fs(cmd)
        @actor.exec!("hadoop fs #{cmd}")
      end
    end

    def Proxy
      attr_accessor :source
      attr_accessor :dest
      def initialize(source_fs, dest_fs)
        @source = source_fs
        @dest = dest_fs
      end

      def cp(source, destination)
      end

      def are_fs_on_same_node?
        @source.actor.equals?(@dest.actor)
      end
    end
  end

  # this class holds delegation to the thing that does the work. 
  # what does that even mean 
  # if you are doing something via ssh then this gives you the ssh connection 
  class Actor 
    include HasLogger

    attr_accessor :ssh_options
    attr_accessor :connected
    attr_accessor :ssh_session

    def initialize(opts={})
      @ssh_options = opts[:ssh_options] || {} 
    end

    # connect lazily so we can share connections when doing mvs 
    def exec!(cmd)
      connect! unless @connected
      if using_ssh?
        logger.debug("ssh: " + cmd)
        ssh_session.exec!(cmd)
      else
        logger.debug(cmd)
        `#{cmd}`
      end
    end

    def connect!
      if using_ssh?
        ssh_opts = @ssh_options.dup
        host = ssh_opts.delete(:host) || "localhost"
        user = ssh_opts.delete(:user) || ENV["USER"]
        ssh_opts[:logger]  ||= self.logger if ENV["DEBUG"]
        ssh_opts[:verbose] ||= :debug      if ENV["DEBUG"]
        @ssh_session = Net::SSH.start(host, user, ssh_opts)
      end
      @connected = true
    end

    def using_ssh?
      @ssh_options.keys.size > 0 ? true : false
    end

    def cleanup
      ssh_session.close if ssh_session
    end

    def equal?(other) 
      if using_ssh?
        return self.ssh_options == other.ssh_options
      else
        super
      end
    end

  end

end
