require "spec_helper"

RSpec.describe RackReverseProxy::Cache::Redis do

  before(:each) {
    ::Redis.new.del("test_key")
  }

  describe "#get" do

    it "should return nil if cache does not exists" do
      expect(subject.get("test_key")).to eq nil
    end

    it "should return cached response if it exists" do
      subject.set("test_key", {test: 1, test2: 2})
      expect(subject.get("test_key")).to eq({test: 1, test2: 2})
      expect(subject.client.get("test_key")).to eq("---\n:test: 1\n:test2: 2\n")
    end

  end

  describe "#set" do
    it "should set cache with assigned key" do
      subject.set("test_key", {test: 1, test2: 2})
      expect(subject.client.get("test_key")).to eq("---\n:test: 1\n:test2: 2\n")
    end

  end

  describe "#gen_key" do
    it "should sanitize uri in gen_key" do
      expect(subject.gen_key("https://test.example.com/test123/2134_123")).to eq("_rack_reverse_proxy.https___test_example_com_test123_2134_123")
    end
  end


end