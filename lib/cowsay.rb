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
      destination = WithPath.new(options[:out]).path

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
      if options[:out]
        options[:out] << output
      end
      @logger.info "Wrote to #{destination}"
      if $? && ![0,172].include?($?.exitstatus)
        raise ArgumentError, "Command exited with status #{$?.exitstatus.to_s}"
      end
      output
    end
  end
end
