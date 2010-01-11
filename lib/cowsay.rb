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
      results = messages.map { |message|
        checked_popen(command, "w+", lambda{message}) do |process|
          process.write(message)
          process.close_write
          process.read
        end
      }
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
  end
end
