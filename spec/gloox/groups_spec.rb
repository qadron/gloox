# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'GlooX Groups' do
  let(:node1) { GlooX::Node.new(url: '0.0.0.0:9999').start }
  let(:node2) { GlooX::Node.new(url: '0.0.0.0:9998', peer: '0.0.0.0:9999').start }

  before do
    node1
    node2
    node1.create_channel('my_nodes')
    sleep 1
  end

  after do
      node1.shutdown
      node2.shutdown
      sleep 2
  end

  it 'shares data between nodes in a group' do
    node2.my_nodes.on_set(:a1) { |k, v| @result = "#{k} => #{v}" }
    node1.my_nodes.set(:a1, 99)
    sleep 1
    expect(@result).to eq('a1 => 99')
  end
end
