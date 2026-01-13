# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GlooX::Node do
  let(:node_port) { 9999 }
  let(:node) { described_class.new(url: "0.0.0.0:#{node_port}" ) }
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
        pending
      expect { node.spawn( *spawn_options ) }.not_to raise_error
    end

    it 'spawns a process with default strategy' do
      node.spawn( *spawn_options )
      sleep 1

      client = Tiq::Client.new( 'localhost:8888' )
      expect(client.alive?).to be_truthy
    end

    it 'raises an error for an unknown strategy' do
        pending
        expect { node.spawn(:unknown, 'Child', 'child.rb', { e: 27 }) }.to raise_error(ArgumentError, /Unknown strategy/)
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
        node.start
        node.preferred(:horizontal) do |url|
          expect(url).to eq('localhost:9997')
        end
      end
    end

    context 'with an invalid strategy' do
      it 'raises an error' do
        expect do
          node.preferred(:invalid) {}
        end.to raise_error(ArgumentError, /Unknown strategy/)
      end
    end

    context 'with resource requirements' do
      let(:node_instance) { described_class.new(url: "0.0.0.0:#{node_port}") }
      
      it 'filters out nodes without sufficient resources' do
        allow(node_instance).to receive(:available_resources).and_return(
          disk: 500_000_000,
          memory: 500_000_000
        )
        
        requirements = { disk: 1_000_000_000, memory: 1_000_000_000 }
        
        node_instance.preferred(:direct, requirements) do |url|
          expect(url).to be_nil
        end
      end
      
      it 'returns URL when node has sufficient resources' do
        allow(node_instance).to receive(:available_resources).and_return(
          disk: 10_000_000_000,
          memory: 10_000_000_000
        )
        allow(node_instance).to receive(:utilization).and_return(0.5)
        
        requirements = { disk: 1_000_000_000, memory: 1_000_000_000 }
        
        node_instance.preferred(:direct, requirements) do |url|
          expect(url).not_to be_nil
        end
      end
    end
  end

  describe '#peek_file_requirements' do
    let(:node_instance) { described_class.new(url: "0.0.0.0:#{node_port}") }
    let(:test_file) { "#{File.dirname(__FILE__)}/../support/fixtures/child_node_with_resources.rb" }
    
    it 'extracts resource requirements from a file' do
      requirements = node_instance.send(:peek_file_requirements, test_file)
      
      expect(requirements).not_to be_nil
      expect(requirements[:disk]).to eq(1_000_000_000)
      expect(requirements[:memory]).to eq(1_000_000_000)
    end
    
    it 'returns nil for files without resource requirements' do
      simple_file = "#{File.dirname(__FILE__)}/../support/fixtures/child_node.rb"
      requirements = node_instance.send(:peek_file_requirements, simple_file)
      
      expect(requirements).to be_nil
    end
    
    it 'returns nil for non-existent files' do
      requirements = node_instance.send(:peek_file_requirements, '/non/existent/file.rb')
      
      expect(requirements).to be_nil
    end
  end

  describe '#fits_available_resources?' do
    let(:node_instance) { described_class.new(url: "0.0.0.0:#{node_port}") }
    
    it 'returns true when requirements fit' do
      allow(node_instance).to receive(:available_resources).and_return(
        disk: 10_000_000_000,
        memory: 10_000_000_000
      )
      
      requirements = { disk: 1_000_000_000, memory: 1_000_000_000 }
      expect(node_instance.send(:fits_available_resources?, requirements)).to be true
    end
    
    it 'returns false when disk requirement exceeds available' do
      allow(node_instance).to receive(:available_resources).and_return(
        disk: 500_000_000,
        memory: 10_000_000_000
      )
      
      requirements = { disk: 1_000_000_000, memory: 1_000_000_000 }
      expect(node_instance.send(:fits_available_resources?, requirements)).to be false
    end
    
    it 'returns false when memory requirement exceeds available' do
      allow(node_instance).to receive(:available_resources).and_return(
        disk: 10_000_000_000,
        memory: 500_000_000
      )
      
      requirements = { disk: 1_000_000_000, memory: 1_000_000_000 }
      expect(node_instance.send(:fits_available_resources?, requirements)).to be false
    end
  end

end
