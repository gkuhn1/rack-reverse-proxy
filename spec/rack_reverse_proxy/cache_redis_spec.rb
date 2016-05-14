require "spec_helper"
require "redis"
require "redis-store"


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
      expect(subject.client.get("test_key")).to eq(Zlib::Deflate.deflate("---\n:test: 1\n:test2: 2\n"))
    end

  end

  describe "#set" do
    it "should set cache with assigned key" do
      subject.set("test_key", {test: 1, test2: 2})
      expect(subject.client.get("test_key")).to eq(Zlib::Deflate.deflate("---\n:test: 1\n:test2: 2\n"))
    end

  end

  describe "#gen_key" do
    it "should sanitize uri in gen_key" do
      expect(subject.gen_key("https://test.example.com/test123/2134_123")).to eq("_rack_reverse_proxy.https___test_example_com_test123_2134_123")
    end
  end

  context "with connection pool" do

    let(:subject) { described_class.new(pool: ::ConnectionPool.new { ::Redis.new }) }

    it "should not initialize a new Redis store" do
      expect(::Redis::Store::Factory).not_to receive(:create)
      subject.get("test_key")
    end
  end

  context "with connection pool options" do

    let(:options) { {pool_size: 2, pool_timeout: 10} }
    let(:subject) { described_class.new(options) }

    it "should initialize a ConnectionPool with options" do
      expect(::ConnectionPool).to receive(:new).with({size: 2, timeout: 10}).and_call_original
      subject.get("test_key")
    end

  end

end