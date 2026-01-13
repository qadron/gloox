# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GlooX::Client do
  let(:url) { '0.0.0.0:9997' }
  let(:node) { GlooX::Node.new(url: url).start }
  
  before do
    node
  end
  
  after do
    node.shutdown
    sleep 1
  end

  describe '#initialize' do
    it 'initializes with a URL string' do
      client = described_class.new(url: url)
      expect(client).to be_a(GlooX::Client)
    end

    it 'stores the URL' do
      client = described_class.new(url: url)
      expect(client.url).to eq(url)
    end

    it 'accepts additional options' do
      client = described_class.new(url: url, timeout: 10)
      expect(client).to be_a(GlooX::Client)
    end

    it 'symbolizes option keys' do
      client = described_class.new('url' => url)
      expect(client.url).to eq(url)
    end
  end

  describe '#url' do
    it 'returns the configured URL' do
      client = described_class.new(url: url)
      expect(client.url).to eq(url)
    end
  end

  describe 'inherited RPC functionality' do
    let(:client) { described_class.new(url: url) }

    it 'can call alive? method on the node' do
      expect(client.alive?).to be_truthy
    end

    it 'can call utilization method on the node' do
      expect(client.utilization).to be_a(Float)
    end
  end
end
