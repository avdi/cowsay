module Cowsay
  class Cow
    def initialize(options={})
      @io_class = options.fetch(:io_class){IO}
    end

    def say(message, options={})
      @io_class.popen("cowsay", "w+") do |process|
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
