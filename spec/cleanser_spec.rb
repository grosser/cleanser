require "spec_helper"

describe Cleanser do
  around { |test| Dir.mktmpdir { |dir| Dir.chdir(dir, &test) } }

  def write(file, content)
    File.open(file, "w") { |f| f.write(content) }
  end

  it "has a VERSION" do
    Cleanser::VERSION.should =~ /^[\.\da-z]+$/
  end

  context "CLI" do
    def cleanser(command, options={})
      sh("#{Bundler.root}/bin/cleanser #{command}", options)
    end

    def sh(command, options={})
      result = `#{command} #{"2>&1" unless options[:keep_output]}`
      raise "#{options[:fail] ? "SUCCESS" : "FAIL"} #{command}\n#{result}" if $?.success? == !!options[:fail]
      result
    end

    it "fails with nothing" do
      cleanser("", :fail => true)
    end

    it "shows version" do
      cleanser("-v").should == "#{Cleanser::VERSION}\n"
    end

    it "shows help" do
      cleanser("-h").should include "Usage"
    end

    context "with test-unit polluter" do
      before do
        write "a.rb", "$a=1"
        write "b.rb", "$b=1"
        write "c.rb", "raise if defined?(RSpec); at_exit { exit($b || 0) }"
      end

      it "finds polluter with test-unit" do
        cleanser("a.rb b.rb c.rb c.rb")
      end

      it "finds polluter with absolute paths" do
        cleanser("#{Dir.pwd}/a.rb #{Dir.pwd}/b.rb #{Dir.pwd}/c.rb #{Dir.pwd}/c.rb")
      end

      it "finds polluter with copy-pasted inspected array" do
        cleanser("'\"a.rb\",\"b.rb\",\"c.rb\"' c.rb")
      end
    end

    context "rspec" do
      it "finds polluter with rspec" do
        write "a.rb", "$a=1"
        write "b.rb", "$b=1"
        write "c.rb", "raise unless defined?(RSpec); at_exit { exit($b || 0) }"
        cleanser("a.rb b.rb c.rb c.rb --rspec")
      end

      it "uses --seed" do
        write "a.rb", <<-RUBY.gsub(/^          /, "")
          describe "random" do
            20.times { |i| it(i) { print "-\#{i}-" } }
          end
        RUBY
        write "b.rb", ""
        write "c.rb", ""
        result = cleanser("a.rb b.rb c.rb a.rb --seed 12345 --rspec", fail: true)
        result.should include("-13-.-8-.-16-.-3-.-15-.-12-.-0-.-10-.-7-.-11-.-6-.-17-.-19-.-18-.-14-.-9-.-4-.-1-.-5-.-2-.")
      end
    end

    it "uses --seed" do
      write "a.rb", <<-RUBY.gsub(/^        /, "")
        require "minitest/autorun"
        class FooTest < Minitest::Test
          20.times { |i| define_method("test_" + i.to_s) { print "-\#{i}-" } }
        end
      RUBY
      write "b.rb", ""
      write "c.rb", ""
      result = cleanser("a.rb b.rb c.rb a.rb --seed 12345", fail: true)
      result.should include("-0-.-13-.-12-.-1-.-11-.-7-.-8-.-10-.-16-.-19-.-4-.-2-.-9-.-3-.-15-.-17-.-14-.-5-.-6-.-18-.")
    end
  end

  describe "#find_polluter" do
    def run_valid_order
      subject.find_polluter(["a.rb", "b.rb", "c.rb", "c.rb"])
    end

    before do
      write "a.rb", "$a=1"
      write "b.rb", "$b=1"
      write "c.rb", "at_exit { exit($b || 0) }"
      subject.stub(:puts)
    end

    it "fails with missing failure" do
      subject.should_receive(:abort).with(/Files have to include the failing file/)
      subject.find_polluter(["a.rb", "b.rb", "c.rb"])
    end

    it "fails with to few files" do
      subject.should_receive(:abort).with(/Files have to be more than 2/)
      subject.find_polluter(["a.rb", "a.rb"])
    end

    it "fail quickly when there is no failure" do
      write "c.rb", ""
      subject.should_receive(:abort).with(/tests pass locally/)
      run_valid_order
    end

    it "fail quickly when file itself faiks" do
      write "c.rb", "exit(1)"
      subject.should_receive(:abort).with(/c.rb fails when run on it's own/)
      run_valid_order
    end

    it "find the polluter" do
      subject.should_receive(:puts).with("Fails when b.rb, c.rb are run together")
      run_valid_order
    end

    it "finds the polluter in a bigger set" do
      10.times { |i| write "#{i}.rb", "$a#{i}=1" }
      subject.should_receive(:puts).with("Fails when b.rb, c.rb are run together")
      subject.find_polluter(["a.rb", "0.rb", "1.rb", "2.rb", "b.rb", "3.rb", "4.rb", "5.rb", "6.rb", "7.rb", "c.rb", "8.rb", "9.rb", "c.rb"])
    end

    context "folder" do
      it "finds the polluter in a folder with _test.rb" do
        FileUtils.mkdir("x")
        FileUtils.mv("b.rb", "x/b_test.rb")
        FileUtils.mv("c.rb", "x/c_test.rb")
        subject.should_receive(:puts).with("Fails when #{Dir["x/*_test.rb"].join(", ")} are run together")
        write("x/x.rb", "raise") # does not run everything
        subject.find_polluter(["x", "x/c_test.rb"])
      end

      it "finds the polluter in a nested folder" do
        FileUtils.mkdir_p("x/y/z")
        FileUtils.mv("b.rb", "x/y/z/b_test.rb")
        FileUtils.mv("c.rb", "x/y/z/c_test.rb")
        subject.should_receive(:puts).with("Fails when #{Dir["x/y/z/*_test.rb"].join(", ")} are run together")
        subject.find_polluter(["x", "x/y/z/c_test.rb"])
      end

      it "finds the polluter in a folder with test_" do
        FileUtils.mkdir("x")
        FileUtils.mv("b.rb", "x/test_b.rb")
        FileUtils.mv("c.rb", "x/test_c.rb")
        subject.should_receive(:puts).with("Fails when #{Dir["x/test_*.rb"].join(", ")} are run together")
        write("x/x.rb", "raise") # does not run everything
        subject.find_polluter(["x", "x/test_c.rb"])
      end

      it "finds the polluter when test pattern cannot be found for folder" do
        FileUtils.mkdir("x")
        FileUtils.mv("b.rb", "x/b.rb")
        FileUtils.mv("c.rb", "x/c.rb")
        subject.should_receive(:puts).with("Fails when #{Dir["x/*.rb"].join(", ")} are run together")
        subject.find_polluter(["x", "x/c.rb"])
      end
    end
  end
end
