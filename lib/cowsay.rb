module Cowsay
  class Cow
    def initialize(options={})
      @io_class = options.fetch(:io_class){IO}
    end

    def say(message)
      @io_class.popen("cowsay", "w+") do |process|
        process.write(message)
        process.close_write
        process.read
      end
    end
  end
end
