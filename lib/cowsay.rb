module Cowsay
  class Cow
    def initialize(options={})
      @io_class = options.fetch(:io_class){IO}
    end

    def say(message, options={})
      command = "cowsay"
      if options[:strings] && options[:strings][:eyes]
        command << " -e '#{options[:strings][:eyes]}'"
      end
      @io_class.popen(command, "w+") do |process|
        process.write(message)
        process.close_write
        result = process.read
        if options[:out]
          options[:out] << result
        end
        result
      end
    end
  end
end
