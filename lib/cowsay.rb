require 'active_support'
require 'logger'
module Cowsay
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
      command = "cowsay"
      if options[:strings] && options[:strings][:eyes]
        command << " -e '#{options[:strings][:eyes]}'"
      end
      out = options.fetch(:out) { NullObject.new }

      messages = case message
                 when Array then message
                 when nil then []
                 else [message]
                 end
      results = []
      messages.each do |message|
        @io_class.popen(command, "w+") do |process|
          results << begin
                       process.write(message)
                       process.close_write
                       result = process.read
                     rescue Errno::EPIPE
                       message
                     end
        end
      end
      output = results.join("\n")    
      out << output
      destination = case options[:out]
                    when nil  then "return value"
                    when File then options[:out].path
                    else options[:out].inspect
                    end
      @logger.info "Wrote to #{destination}"
      if $? && ![0,172].include?($?.exitstatus)
        raise ArgumentError, "Command exited with status #{$?.exitstatus.to_s}"
      end
      output
    end
  end
end
