require "spec_helper"

describe Cleanser do
  it "has a VERSION" do
    Cleanser::VERSION.should =~ /^[\.\da-z]+$/
  end

  describe "#find_polluter" do
    def write(file, content)
      File.open(file, "w") { |f| f.write(content) }
    end

    def run_valid_order
      subject.find_polluter("a.rb", "b.rb", "c.rb", "c.rb")
    end

    around { |test| Dir.mktmpdir { |dir| Dir.chdir(dir, &test) } }

    before do
      write "a.rb", "$a=1"
      write "b.rb", "$b=1"
      write "c.rb", "exit($b || 0)"
      subject.stub(:puts)
    end

    it "fails with missing failure" do
      subject.should_receive(:abort).with(/Files have to include the failing file/)
      subject.find_polluter("a.rb", "b.rb", "c.rb")
    end

    it "fails with to few files" do
      subject.should_receive(:abort).with(/Files have to be more than 2/)
      subject.find_polluter("a.rb", "a.rb")
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
      subject.find_polluter("a.rb", "0.rb", "1.rb", "2.rb", "b.rb", "3.rb", "4.rb", "5.rb", "6.rb", "7.rb", "c.rb", "8.rb", "9.rb", "c.rb")
    end
  end
end
