# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gloox::Utilities do
  # Create a test class that includes the Utilities module
  let(:test_class) do
    Class.new do
      include Gloox::Utilities
      
      # Mock port_available? for testing
      def port_available?(port)
        # Consider ports above 50000 as available for testing
        port > 50000
      end
    end
  end
  
  let(:test_instance) { test_class.new }

  describe '.available_port_mutex' do
    it 'returns a Mutex instance' do
      expect(described_class.available_port_mutex).to be_a(Mutex)
    end

    it 'returns the same mutex on multiple calls' do
      mutex1 = described_class.available_port_mutex
      mutex2 = described_class.available_port_mutex
      expect(mutex1).to equal(mutex2)
    end
  end

  describe '#random_port' do
    it 'returns a port number within default range' do
      port = test_instance.random_port
      expect(port).to be >= 1025
      expect(port).to be <= 65535
    end

    it 'returns a port number within custom range' do
      port = test_instance.random_port([8000, 9000])
      expect(port).to be >= 8000
      expect(port).to be <= 9000
    end

    it 'returns different ports on multiple calls (statistically)' do
      ports = 10.times.map { test_instance.random_port }
      # Very unlikely to get all the same port
      expect(ports.uniq.length).to be > 1
    end
  end

  describe '#available_port' do
    it 'returns a port number' do
      port = test_instance.available_port
      expect(port).to be_a(Integer)
    end

    it 'returns a port that is marked as available' do
      port = test_instance.available_port([50001, 60000])
      expect(port).to be > 50000
    end

    it 'respects custom range' do
      port = test_instance.available_port([50001, 55000])
      expect(port).to be >= 50001
      expect(port).to be <= 55000
    end

    it 'is thread-safe' do
      ports = []
      threads = 5.times.map do
        Thread.new do
          ports << test_instance.available_port([50001, 60000])
        end
      end
      threads.each(&:join)
      
      expect(ports.length).to eq(5)
      ports.each do |port|
        expect(port).to be > 50000
      end
    end
  end
end
