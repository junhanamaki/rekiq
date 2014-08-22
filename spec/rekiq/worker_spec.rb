require 'spec_helper'
require 'sidekiq'
require 'rekiq/worker'

describe Rekiq::Worker do
  class ExampleWorker
    include Sidekiq::Worker
  end

  class RekiqCancelMethodUndefinedExampleWorker
    include Sidekiq::Worker
    sidekiq_options rekiq_cancel_method: :cancel
  end

  class RekiqCancelMethodDefinedExampleWorker
    include Sidekiq::Worker
    sidekiq_options rekiq_cancel_method: :cancel

    def cancel
    end
  end

  context 'class includes Sidekiq::Worker module' do
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

        context 'for worker with rekiq_cancel_method set with ' \
                'non defined method' do
          before do
            begin
              @jid =
                RekiqCancelMethodUndefinedExampleWorker.perform_recurringly(schedule)
            rescue
            end
          end

          it 'raises error' do
            expect do
              RekiqCancelMethodUndefinedExampleWorker.perform_recurringly(schedule)
            end.to raise_error
          end

          it 'does not schedule worker' do
            expect(RekiqCancelMethodUndefinedExampleWorker.jobs.count).to eq(0)
          end
        end

        context 'for worker with rekiq_cancel_method set with ' \
                'defined method' do
          before do
            @jid = RekiqCancelMethodDefinedExampleWorker.perform_recurringly(schedule)
          end

          it 'does not raise error' do
            expect do
              RekiqCancelMethodDefinedExampleWorker.perform_recurringly(schedule)
            end.not_to raise_error
          end

          it 'returns created jid' do
            expect(@jid).not_to be_nil
          end

          it 'schedules worker' do
            expect(RekiqCancelMethodDefinedExampleWorker.jobs.count).to eq(1)
          end

          it 'schedules worker for one hour from now' do
            expect(RekiqCancelMethodDefinedExampleWorker.jobs[0]['at']).to eq(time.to_f)
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

        context 'rekiq_cancel_args with 2 arguments' do
          let(:rekiq_cancel_args) { ['args1', 'args2'] }
          before do
            @jid = ExampleWorker.perform_recurringly(schedule) do |config|
                config.rekiq_cancel_args *rekiq_cancel_args
              end
          end

          it 'returns created job id' do
            expect(@jid).not_to be_nil
          end

          it 'schedules worker' do
            expect(ExampleWorker.jobs.count).to eq(1)
          end

          it 'yields once if block given' do
            expect do |b|
              ExampleWorker.perform_recurringly(schedule, &b)
            end.to yield_control.once
          end

          it 'creates key rq:ca in job hash' do
            expect(ExampleWorker.jobs[0].key?('rq:ca')).to eq(true)
          end

          describe 'value under rq:ca key in job hash' do
            let(:value) { ExampleWorker.jobs[0]['rq:ca'] }

            it 'is an array' do
              expect(value.class).to eq(Array)
            end

            it 'has count equal to number of rekiq_cancel_args' do
              expect(value.count).to eq(rekiq_cancel_args.count)
            end

            it 'has first element equal to first arg in rekiq_cancel_args' do
              expect(value[0]).to eq(rekiq_cancel_args[0])
            end

            it 'has second element equal to second arg in rekiq_cancel_args' do
              expect(value[1]).to eq(rekiq_cancel_args[1])
            end
          end
        end

        context 'shift set to minus 5 minutes' do
          let(:shift) { -5 * 60 }
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

          it 'yields once if block given' do
            expect do |b|
              ExampleWorker.perform_recurringly(schedule, &b)
            end.to yield_control.once
          end

          it 'sets shift in position 1 of array under key rq:job' do
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