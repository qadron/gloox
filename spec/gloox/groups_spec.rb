# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'GlooX Groups' do
  let(:agent1) { GlooX::Agent.new(url: 'localhost:9999').start }
  let(:agent2) { GlooX::Agent.new(url: 'localhost:9998', peer: 'localhost:9999').start }

  before do
    agent1.create_channel('my_agents')
    sleep 1
  end

  after do
      agent1.stop
      agent2.stop
      sleep 2
  end

  it 'shares data between agents in a group' do
    agent2.my_agents.on_set(:a1) { |k, v| @result = "#{k} => #{v}" }
    agent1.my_agents.set(:a1, 99)
    sleep 1
    expect(@result).to eq('a1 => 99')
  end
end
