require 'spec_helper'
require 'sidekiq'
require 'rekiq/worker'

describe Rekiq::Worker do
  class ExampleWorker
    include Sidekiq::Worker
  end

  context 'Class includes Sidekiq::Worker module' do
    it 'responds to perform_recurringly' do
      ExampleWorker.respond_to? :perform_recurringly
    end

    describe '.perform_recurringly' do
      context 'scheduled one hour from now' do
        let(:time)     { Time.now + 3600 }
        let(:schedule) { IceCube::Schedule.new(time) }
        before do
          @jid = ExampleWorker.perform_recurringly(schedule)
        end

        it 'returns created jid' do
          expect(@jid).not_to be_nil
        end

        it 'schedules worker' do
          expect(ExampleWorker.jobs.count).to eq(1)
        end

        it 'schedules worker for one hour from now' do
          expect(ExampleWorker.jobs[0]['at']).to eq(time.to_f)
        end
      end

      context 'scheduled one hour from now ' \
              'shift set to minus 5 minutes' do
        let(:time)     { Time.now + 3600 }
        let(:schedule) { IceCube::Schedule.new(time) }
        let(:shift)    { -5 * 60 }
        before do
          @jid = ExampleWorker.perform_recurringly(schedule) do |options|
              options.shift = shift
            end
        end

        it 'returns created job id' do
          expect(@jid).not_to be_nil
        end

        it 'schedules worker' do
          expect(ExampleWorker.jobs.count).to eq(1)
        end

        it 'yields once' do
          expect do |b|
            ExampleWorker.perform_recurringly(schedule, &b)
          end.to yield_control.once
        end

        it 'sets shift in job' do
          hash = ExampleWorker.jobs[0]['mandragora:job']

          expect(hash['shift']).to eq(shift)
        end

        it 'schedules worker for one hour minus 5 minutes from now' do
          expect(ExampleWorker.jobs[0]['at']).to eq(time.to_f + shift)
        end
      end
    end
  end
end