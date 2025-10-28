# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GlooX::Agent do
  let(:agent_port) { 9999 }
  let(:agent) { described_class.new(url: "localhost:#{agent_port}" ).start }
  let(:spawn_options) do
      [
        'MyNode',
        "#{File.dirname(__FILE__)}/../support/fixtures/child_node.rb",
        { url: 'localhost:8888' }
      ]
  end

  before :each do
      agent
  end
  after :each do
      agent.shutdown
      sleep 2
  end

  describe '#start' do
    it 'starts the agent successfully' do
      expect { agent }.not_to raise_error
    end
  end

  describe '#spawn' do
    it 'spawns a process with default strategy' do
        pending
      expect { agent.spawn( *spawn_options ) }.not_to raise_error
    end

    it 'spawns a process with default strategy' do
      agent.spawn( *spawn_options )
      sleep 1

      client = Tiq::Client.new( 'localhost:8888' )
      expect(client.alive?).to be_truthy
    end

    it 'raises an error for an unknown strategy' do
        pending
        expect { agent.spawn(:unknown, 'Child', 'child.rb', { e: 27 }) }.to raise_error(ArgumentError, /Unknown strategy/)
    end
  end

  describe '#utilization' do
    it 'returns the current utilization' do
      expect(agent.utilization).to be_a(Float)
    end
  end

  describe '#preferred' do
    context 'with a valid strategy' do
      it 'returns the preferred URL' do
        agent.start
        agent.preferred(:horizontal) do |url|
          expect(url).to eq('localhost:9997')
        end
      end
    end

    context 'with an invalid strategy' do
      it 'raises an error' do
        expect do
          agent.preferred(:invalid) {}
        end.to raise_error(ArgumentError, /Unknown strategy/)
      end
    end
  end

end
