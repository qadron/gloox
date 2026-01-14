# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GlooX::Node do
  let(:node_port) { 9999 }
  let(:node) { described_class.new(url: "0.0.0.0:#{node_port}" ) }
  let(:client) { GlooX::Client.new url: node.url }
  let(:spawn_options) do
      [
        'MyNode',
        "#{File.dirname(__FILE__)}/../support/fixtures/child_node.rb",
        { url: '0.0.0.0:8888' }
      ]
  end

  before :each do
      node.start
  end
  after :each do
      node.shutdown
      sleep 2
  end

  describe '#start' do
    it 'starts the node successfully' do
      expect { node }.not_to raise_error
    end
  end

  describe '#spawn' do
    it 'spawns a process with default strategy' do
      expect { client.spawn( *spawn_options ) }.not_to raise_error
    end

    it 'spawns a process with default strategy' do
      client.spawn( *spawn_options )
      sleep 3

      expect(client.alive?).to be_truthy
    end

    it 'raises an error for an unknown strategy' do
      expect(client.spawn('Child', 'child.rb', { e: 27 }, :unknown_strategy)).to be :error_unknown_strategy
    end
  end

  describe '#utilization' do
    it 'returns the current utilization' do
      expect(node.utilization).to be_a(Float)
    end
  end

  describe '#preferred' do
    context 'with a valid strategy' do
      it 'returns the preferred URL' do
        options = ['MyNode',
          "#{File.dirname(__FILE__)}/../support/fixtures/child_node.rb"]

        url = client.preferred(*(options | [:horizontal]))
        expect(url).to eq("0.0.0.0:#{node_port}")
      end
    end

    context 'with an invalid strategy' do
      it 'raises an error' do
        options = ['MyNode',
                   "#{File.dirname(__FILE__)}/../support/fixtures/child_node.rb"]

        expect(client.preferred(*(options | [:invalid]))).to be :error_unknown_strategy
      end
    end

    context 'with vertical strategy' do
      it 'returns a URL for vertical scaling' do
        options = ['MyNode',
          "#{File.dirname(__FILE__)}/../support/fixtures/child_node.rb"]

        url = client.preferred(*(options | [:vertical]))
        expect(url).to eq("0.0.0.0:#{node_port}")
      end
    end

    context 'with direct strategy' do
      it 'returns the current node URL' do
        options = ['MyNode',
          "#{File.dirname(__FILE__)}/../support/fixtures/child_node.rb"]

        url = client.preferred(*(options | [:direct]))
        expect(url).to eq("0.0.0.0:#{node_port}")
      end
    end

    context 'with nil strategy (defaults to vertical)' do
      it 'returns a URL' do
        options = ['MyNode',
          "#{File.dirname(__FILE__)}/../support/fixtures/child_node.rb"]

        url = client.preferred(*options)
        expect(url).to eq("0.0.0.0:#{node_port}")
      end
    end
  end

  describe '#fits?' do
    it 'returns true when a class fits on the node' do
      result = node.fits?('MyNode', "#{File.dirname(__FILE__)}/../support/fixtures/child_node.rb")
      expect(result).to be_truthy
    end

    it 'works with callback block' do
      result = nil
      node.fits?('MyNode', "#{File.dirname(__FILE__)}/../support/fixtures/child_node.rb") do |fits|
        result = fits
      end
      expect(result).to be_truthy
    end
  end

  describe 'PREFERENCE_STRATEGIES constant' do
    it 'includes expected strategies' do
      expect(GlooX::Node::PREFERENCE_STRATEGIES).to include(nil)
      expect(GlooX::Node::PREFERENCE_STRATEGIES).to include(:horizontal)
      expect(GlooX::Node::PREFERENCE_STRATEGIES).to include(:vertical)
      expect(GlooX::Node::PREFERENCE_STRATEGIES).to include(:direct)
    end

    it 'is a Set' do
      expect(GlooX::Node::PREFERENCE_STRATEGIES).to be_a(Set)
    end
  end

end
