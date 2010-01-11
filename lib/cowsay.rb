require 'active_support'
require 'logger'
require 'delegate'

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

  def nil?
    true
  end
end

def Maybe(value)
  value.nil? ? NullObject.new : value
end
    
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

  class Cow
    def initialize(options={})
      @io_class = options.fetch(:io_class){IO}
      @logger   = options.fetch(:logger){Logger.new($stderr)}
    end

    def say(message, options={})
      return "" if message.nil?
      options[:cowfile] and assert(options[:cowfile].to_s !~ /^\s*$/)

      width       = options.fetch(:width) {40}
      eyes        = Maybe(options[:strings])[:eyes]
      cowfile     = options[:cowfile]
      destination = WithPath.new(options[:out]).path
      out         = options.fetch(:out) { NullObject.new }
      messages    = Array(message)
      command     = "cowsay"
      command << " -W #{width}"
      command << " -e '#{options[:strings][:eyes]}'" unless eyes.nil?
      command << " -f #{options[:cowfile]}" unless cowfile.nil?

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
