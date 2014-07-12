require "spec_helper"

describe Cleanser do
  it "has a VERSION" do
    Cleanser::VERSION.should =~ /^[\.\da-z]+$/
  end
end
