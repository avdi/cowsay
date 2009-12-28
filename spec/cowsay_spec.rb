require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

module Cowsay
  describe Cow do
    before :each do
      @process  = stub("process", :read => "OUTPUT").as_null_object
      @io_class = stub("IO Class")
      @io_class.stub!(:popen).and_yield(@process)
      @it       = Cow.new(:io_class => @io_class)
    end

    it "should be able to say hello" do
      @process.should_receive(:write).with("hello")
      @it.say("hello")
    end

    it "should start the cowsay process" do
      @io_class.should_receive(:popen).with("cowsay", anything)
      @it.say("foo")
    end

    it "should close the cowsay process after writing" do
      @process.should_receive(:write).ordered
      @process.should_receive(:close_write).ordered
      @it.say("foo")
    end

    it "should read process output after closing process input" do
      @process.should_receive(:close_write).ordered
      @process.should_receive(:read).ordered
      @it.say("foo")
    end

    it "should return the result of reading from the process" do
      @it.say("foo").should be == "OUTPUT"
    end

    it "should open cowsay process for read/write" do
      @io_class.should_receive(:popen).with(anything, 'w+')
      @it.say("foo")
    end
  end
end
