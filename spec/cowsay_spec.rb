require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'tempfile'

module Cowsay
  describe Cow do

    def set_child_exit_status(status)
      # $? is read-only so we can't set it manually. Instead we have to start an
      # actual process and exit with the given status.
      open("|-") do |pipe| exit!(status) if pipe.nil? end
    end

    before :each do
      set_child_exit_status(0)
      @process  = stub("process", :read => "OUTPUT").as_null_object
      @io_class = stub("IO Class")
      @log      = stub("Log").as_null_object
      @io_class.stub!(:popen).and_yield(@process)
      @it       = Cow.new(:io_class => @io_class, :logger => @log)
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

    it "should pass the -e flag if 'eyes' string set" do
      @io_class.should_receive(:popen).with(/\-e 'oO\'/, anything)
      @it.say("moo", :strings => { :eyes => 'oO' })
    end

    context "given an output stream" do
      it "should write to given output stream" do
        out = StringIO.new
        @it.say("moo", :out => out)
        out.string.should be == "OUTPUT"
      end

      it "should log the filename of output file" do
        Tempfile.open('cowsay_spec') do |f|
          @log.should_receive(:info).with(/#{f.path}/)
          @it.say("moo", :out => f)
        end
      end
      
    end

    context "given a non-file output stream" do
      it "should log the object in string form" do
        out = StringIO.new
        out.stub!(:inspect).and_return("<output>")
        @log.should_receive(:info).with(/<output>/)
        @it.say("moo", :out => out)
      end
    end

    context "when cowsay command is missing" do
      it "should just output the bare message" do
        @process.should_receive(:write).and_raise(Errno::EPIPE)
        @it.say("cluck").should be == "cluck"
      end
    end

    context "when the command returns a non-zero status" do
      it "should raise an error" do
        set_child_exit_status(1)
        lambda do 
          @it.say("moo")
        end.should raise_error(ArgumentError)
      end
    end

    context "multiple messages" do
      it "should render each message in order" do
        @process.should_receive(:write).with("foo").ordered
        @process.should_receive(:write).with("bar").ordered
        @it.say(["foo", "bar"])
      end
    end

    context "nil message" do
      it "should return empty string" do
        @it.say(nil).should be == ""
      end
    end

    context "bad :out option" do
      it "should raise ArgumentError" do
        lambda do
          @it.say("whatever", :out => Object.new)
        end.should raise_error(ArgumentError)
      end
    end
  end
end
