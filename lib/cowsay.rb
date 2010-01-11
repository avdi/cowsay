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
      destination = case options[:out]
                    when nil  then "return value"
                    when File then options[:out].path
                    else options[:out].inspect
                    end
      @logger.info "Wrote to #{destination}"
      check_child_exit_status!
      output
    end

    private
    
    def check_child_exit_status!(status=$?)
      status ||= OpenStruct.new(:exitstatus => 0)
      unless [0,172].include?(status.exitstatus)
        raise ArgumentError, "Command exited with status #{status.exitstatus}"
      end      
    end
  end
end
