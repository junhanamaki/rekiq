require 'spec_helper'
require 'sidekiq'
require 'rekiq/worker'

describe Rekiq::Worker do
  class ExampleWorker
    include Sidekiq::Worker
  end

  class CancellerUndefinedExampleWorker
    include Sidekiq::Worker
    sidekiq_options recurrence_canceller_name: :cancel
  end

  class CancellerDefinedExampleWorker
    include Sidekiq::Worker
    sidekiq_options recurrence_canceller_name: :cancel

    def cancel
    end
  end

  context 'Class includes Sidekiq::Worker module' do
    it 'responds to perform_recurringly' do
      ExampleWorker.respond_to? :perform_recurringly
    end

    describe '.perform_recurringly' do
      context 'for schedule that does not return next occurrence' do
        let(:schedule) { IceCube::Schedule.new(Time.now - 3600) }
        before do
          @jid = ExampleWorker.perform_recurringly(schedule)
        end

        it 'returns nil' do
          expect(@jid).to eq(nil)
        end

        it 'does not schedule worker' do
          expect(ExampleWorker.jobs.count).to eq(0)
        end
      end

      context 'scheduled one hour from now' do
        let(:time)     { Time.now + 3600 }
        let(:schedule) { IceCube::Schedule.new(time) }

        context 'for worker with recurrence_canceller_name set with ' \
                'non defined method' do
          before do
            begin
              @jid =
                CancellerUndefinedExampleWorker.perform_recurringly(schedule)
            rescue
            end
          end

          it 'raises error' do
            expect do
              CancellerUndefinedExampleWorker.perform_recurringly(schedule)
            end.to raise_error
          end

          it 'does not schedule worker' do
            expect(CancellerUndefinedExampleWorker.jobs.count).to eq(0)
          end
        end

        context 'for worker with recurrence_canceller_name set with ' \
                'defined method' do
          before do
            @jid = CancellerDefinedExampleWorker.perform_recurringly(schedule)
          end

          it 'does not raise error' do
            expect do
              CancellerDefinedExampleWorker.perform_recurringly(schedule)
            end.not_to raise_error
          end

          it 'returns created jid' do
            expect(@jid).not_to be_nil
          end

          it 'schedules worker' do
            expect(CancellerDefinedExampleWorker.jobs.count).to eq(1)
          end

          it 'schedules worker for one hour from now' do
            expect(CancellerDefinedExampleWorker.jobs[0]['at']).to eq(time.to_f)
          end
        end

        context 'invoked without config' do
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

        context 'shift set to minus 5 minutes' do
          let(:shift)    { -5 * 60 }
          before do
            @jid = ExampleWorker.perform_recurringly(schedule) do |config|
                config.shift = shift
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

          it 'sets shift in rq:job' do
            array = ExampleWorker.jobs[0]['rq:job']

            expect(array[1]).to eq(shift)
          end

          it 'schedules worker for one hour minus 5 minutes from now' do
            expect(ExampleWorker.jobs[0]['at']).to eq(time.to_f + shift)
          end
        end
      end
    end
  end
end