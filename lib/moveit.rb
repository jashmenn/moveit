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

      def file_list(cmd)
        output = @actor.exec!(cmd)
        output.split("\n")
      end

      def cleanup
        @actor.cleanup
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
        ssh_session.exec!(cmd)
      else
        logger.debug(cmd)
        `#{cmd}`
      end
    end

    def connect!
      if using_ssh?
        host = @ssh_options.delete(:host) || "localhost"
        user = @ssh_options.delete(:user) || ENV["USER"]
        @ssh_options[:logger]  ||= self.logger if ENV["DEBUG"]
        @ssh_options[:verbose] ||= :debug      if ENV["DEBUG"]
        @ssh_session = Net::SSH.start(host, user, @ssh_options)
      end
      @connected = true
    end

    def using_ssh?
      ssh_options.keys.size > 0 ? true : false
    end

    def cleanup
      ssh_session.close if ssh_session
    end

  end

end
