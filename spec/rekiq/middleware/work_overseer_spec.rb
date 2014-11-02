require 'spec_helper'

describe Rekiq::Middleware::WorkOverseer do
  class WorkOverseerTestWorker
    include Sidekiq::Worker

    sidekiq_options queue: 'work_overseer_test_worker'
  end

  class WorkOverseerCancelTestWorker
    include Sidekiq::Worker

    sidekiq_options queue: 'work_overseer_test_worker',
                    rekiq_cancel_method: :cancel

    def cancel(bool)
      bool
    end
  end

  describe '#call' do
    let(:args)        { [] }
    let(:schedule)    { IceCube::Schedule.new(Time.new + 3600) }
    let(:overseer)    { Rekiq::Middleware::WorkOverseer.new }
    let(:cancel_args) { nil }
    let(:contract) do
      build :contract, schedule: schedule, cancel_args: cancel_args
    end

    context 'worker without rekiq_cancel_method configured' do
      let(:worker) { WorkOverseerTestWorker.new }
      let(:queue)  { WorkOverseerTestWorker.get_sidekiq_options['queue'] }

      context 'msg with rq:ctr key (existing contract), ' \
              'with rq:sdl key (value is irrelevant)' do
        let(:msg) do
          { 'rq:ctr' => contract.to_hash, 'args' => args, 'rq:sdl' => nil }
        end

        it 'yields once' do
          expect do |b|
            overseer.call(worker, msg, queue, &b)
          end.to yield_control.once
        end

        it 'schedules worker' do
          overseer.call(worker, msg, queue) {}

          expect(WorkOverseerTestWorker.jobs.count).to eq(1)
        end

        it 'removes key rq:sdl from message after invocation' do
          overseer.call(worker, msg, queue) {}

          expect(msg.key?('rq:sdl')).to eq(false)
        end
      end

      context 'msg without rq:ctr key' do
        let(:msg) { {} }

        it 'yields once' do
          expect do |b|
            overseer.call(worker, msg, queue, &b)
          end.to yield_control.once
        end

        it 'does not schedule worker' do
          overseer.call(worker, msg, queue) {}

          expect(WorkOverseerTestWorker.jobs.count).to eq(0)
        end
      end

      context 'msg without key rq:sdl but with key rq:ctr' do
        let(:msg) { { 'rq:ctr' => contract.to_hash, 'args' => args } }

        it 'yields once' do
          expect do |b|
            overseer.call(worker, msg, queue, &b)
          end.to yield_control.once
        end

        it 'does not schedule next work' do
          overseer.call(worker, msg, queue) {}

          expect(WorkOverseerTestWorker.jobs.count).to eq(0)
        end
      end
    end

    context 'worker with rekiq_cancel_method configured' do
      let(:worker) { WorkOverseerCancelTestWorker.new }
      let(:queue)  { WorkOverseerCancelTestWorker.get_sidekiq_options['queue'] }

      context 'msg with keys rc:ctr and rc:sdl' do
        let(:msg) do
          { 'rq:ctr' => contract.to_hash, 'args' => args, 'rq:sdl' => nil }
        end

        context 'work is cancelled by cancel method' do
          let(:cancel_args) { true }

          it 'does not yield' do
            expect do |b|
              overseer.call(worker, msg, queue, &b)
            end.not_to yield_control
          end

          it 'does not schedule next work' do
            overseer.call(worker, msg, queue) {}

            expect(WorkOverseerCancelTestWorker.jobs.count).to eq(0)
          end
        end

        context 'work is not cancelled by cancel method' do
          let(:cancel_args) { false }

          it 'yields given block' do
            expect do |b|
              overseer.call(worker, msg, queue, &b)
            end.to yield_control.once
          end

          it 'it schedules work' do
            overseer.call(worker, msg, queue) {}

            expect(WorkOverseerCancelTestWorker.jobs.count).to eq(1)
          end

          it 'removes key rq:sdl from message after invocation' do
            overseer.call(worker, msg, queue) {}

            expect(msg.key?('rq:sdl')).to eq(false)
          end
        end

        context 'contract with incorrect arity of cancel_args' do
          let(:cancel_args) { [true, false] }
          let(:msg) do
            { 'rq:ctr' => contract.to_hash, 'args' => args }
          end

          it 'raises error' do
            expect do |b|
              overseer.call(worker, msg, queue, &b)
            end.to raise_error
          end
        end
      end
    end
  end
end