# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GlooX::Agent do
  let(:agent_port) { 9999 }
  let(:agent) { described_class.new(url: "0.0.0.0:#{agent_port}" ) }
  let(:client) { GlooX::Client.new url: agent.url }
  let(:spawn_options) do
      [
        'MyAgent',
        "#{File.dirname(__FILE__)}/../support/fixtures/child_agent.rb",
        { url: '0.0.0.0:8888' }
      ]
  end

  before :each do
      agent.start
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
      expect(agent.utilization).to be_a(Float)
    end
  end

  describe '#preferred' do
    context 'with a valid strategy' do
      it 'returns the preferred URL' do
        options = ['MyAgent',
          "#{File.dirname(__FILE__)}/../support/fixtures/child_agent.rb"]

        url = client.preferred(*(options | [:horizontal]))
        expect(url).to eq("0.0.0.0:#{agent_port}")
      end
    end

    context 'with an invalid strategy' do
      it 'raises an error' do
        options = ['MyAgent',
                   "#{File.dirname(__FILE__)}/../support/fixtures/child_agent.rb"]

        expect(client.preferred(*(options | [:invalid]))).to be :error_unknown_strategy
      end
    end

    context 'with vertical strategy' do
      it 'returns a URL for vertical scaling' do
        options = ['MyAgent',
          "#{File.dirname(__FILE__)}/../support/fixtures/child_agent.rb"]

        url = client.preferred(*(options | [:vertical]))
        expect(url).to eq("0.0.0.0:#{agent_port}")
      end
    end

    context 'with direct strategy' do
      it 'returns the current agent URL' do
        options = ['MyAgent',
          "#{File.dirname(__FILE__)}/../support/fixtures/child_agent.rb"]

        url = client.preferred(*(options | [:direct]))
        expect(url).to eq("0.0.0.0:#{agent_port}")
      end
    end

    context 'with nil strategy (defaults to vertical)' do
      it 'returns a URL' do
        options = ['MyAgent',
          "#{File.dirname(__FILE__)}/../support/fixtures/child_agent.rb"]

        url = client.preferred(*options)
        expect(url).to eq("0.0.0.0:#{agent_port}")
      end
    end
  end

  describe '#fits?' do
    it 'returns true when a class fits on the agent' do
      result = agent.fits?('MyAgent', "#{File.dirname(__FILE__)}/../support/fixtures/child_agent.rb")
      expect(result).to be_truthy
    end

    it 'works with callback block' do
      result = nil
      agent.fits?('MyAgent', "#{File.dirname(__FILE__)}/../support/fixtures/child_agent.rb") do |fits|
        result = fits
      end
      expect(result).to be_truthy
    end
  end

  describe 'PREFERENCE_STRATEGIES constant' do
    it 'includes expected strategies' do
      expect(GlooX::Agent::PREFERENCE_STRATEGIES).to include(nil)
      expect(GlooX::Agent::PREFERENCE_STRATEGIES).to include(:horizontal)
      expect(GlooX::Agent::PREFERENCE_STRATEGIES).to include(:vertical)
      expect(GlooX::Agent::PREFERENCE_STRATEGIES).to include(:direct)
    end

    it 'is a Set' do
      expect(GlooX::Agent::PREFERENCE_STRATEGIES).to be_a(Set)
    end
  end

end
