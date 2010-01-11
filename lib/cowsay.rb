require 'active_support'
require 'logger'
require 'delegate'

module Cowsay
  class WithPath < SimpleDelegator
    def path
      case __getobj__
      when File then super
      when nil then "return value"
      else inspect
      end
    end
  end

  class NullObject
    def initialize
      @origin = caller.first
    end

    def __null_origin__
      @origin
    end

    def method_missing(*args, &block)
      self
    end
  end

  def Maybe(value)
    value.nil? ? NullObject.new : value
  end
    
  class Cow
    def initialize(options={})
      @io_class = options.fetch(:io_class){IO}
      @logger   = options.fetch(:logger){Logger.new($stderr)}
    end

    def say(message, options={})
      return "" if message.nil?
      options[:cowfile] and assert(options[:cowfile].to_s !~ /^\s*$/)
      command = "cowsay"
      width = options.fetch(:width) {40}
      command << " -W #{width}"
      if options[:strings] && options[:strings][:eyes]
        command << " -e '#{options[:strings][:eyes]}'"
      end
      if options[:cowfile]
        command << " -f #{options[:cowfile]}"
      end
      destination = WithPath.new(options[:out]).path
      out = options.fetch(:out) { NullObject.new }
      messages = Array(message)

      results = messages.map { |message|
        checked_popen(command, "w+", lambda{message}) do |process|
          process.write(message)
          process.close_write
          process.read
        end
      }
      output = results.join("\n")    
      out << output

      @logger.info "Wrote to #{destination}"
      output
    end

    private

    def checked_popen(command, mode, fail_action)
      check_child_exit_status do
        @io_class.popen(command, "w+") do |process|
          yield(process)
        end
      end
    rescue Errno::EPIPE
      fail_action.call
    end
    
    def check_child_exit_status
      result = yield
      status = $? || OpenStruct.new(:exitstatus => 0)
      unless [0,172].include?(status.exitstatus)
        raise ArgumentError, 
              "Command exited with status #{status.exitstatus}"
      end
      result
    end

    def assert(value, message="Assertion failed")
      raise Exception, message, caller unless value
    end
  end
end
