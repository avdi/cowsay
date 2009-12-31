require 'active_support'
require 'logger'
module Cowsay
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
      result = @io_class.popen(command, "w+") do |process|
        result = begin
                   process.write(message)
                   process.close_write
                   result = process.read
                 rescue Errno::EPIPE
                   message
                 end
        if options[:out]
          options[:out] << result
        end
        destination = case options[:out]
                      when nil  then "return value"
                      when File then options[:out].path
                      else options[:out].inspect
                      end
        @logger.info "Wrote to #{destination}"
        result
      end
      if $? && ![0,172].include?($?.exitstatus)
        raise ArgumentError, $?.exitstatus.to_s
      end
      result
    end
  end
end
