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
    let(:schedule) do
      IceCube::Schedule.new(Time.new + 3600) do |s|
        s.rrule IceCube::Rule.daily
      end
    end
    let(:overseer)    { Rekiq::Middleware::WorkOverseer.new }
    let(:cancel_args) { nil }
    let(:contract) do
      build :contract, schedule: schedule, cancel_args: cancel_args
    end
    let(:scheduled_work_time) { Time.at(Time.now.to_f) }

    before { overseer.call(worker, msg, queue) {} rescue nil }

    context 'worker without rekiq_cancel_method configured' do
      let(:worker) { WorkOverseerTestWorker.new }
      let(:queue)  { WorkOverseerTestWorker.get_sidekiq_options['queue'] }

      context 'msg with rq:ctr key (existing contract), ' \
              'with rq:sdl key (value is irrelevant), '   \
              'with rq:at key' do
        let(:msg) do
          {
            'rq:ctr' => contract.to_hash,
            'args'   => args,
            'rq:sdl' => nil,
            'rq:at'  => scheduled_work_time.to_f
          }
        end

        it 'yields once' do
          expect do |b|
            overseer.call(worker, msg, queue, &b)
          end.to yield_control.once
        end

        it 'schedules worker' do
          expect(WorkOverseerTestWorker.jobs.count).to eq(1)
        end

        it 'sets scheduled_work_time attribute in worker' do
          expect(worker.scheduled_work_time).to eq(scheduled_work_time.utc)
        end

        it 'sets estimated_next_work_time attribute in worker' do
          expect(worker.estimated_next_work_time).to \
            eq(schedule.next_occurrence)
        end

        it 'removes key rq:sdl from message after invocation' do
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
          expect(WorkOverseerTestWorker.jobs.count).to eq(0)
        end

        it 'scheduled_work_time in worker is unchanged (nil)' do
          expect(worker.scheduled_work_time).to be_nil
        end
      end

      context 'msg without key rq:sdl but with key rq:ctr and rq:at' do
        let(:msg) do
          {
            'rq:ctr' => contract.to_hash,
            'args'   => args,
            'rq:at'  => scheduled_work_time.to_f
          }
        end

        it 'yields once' do
          expect do |b|
            overseer.call(worker, msg, queue, &b)
          end.to yield_control.once
        end

        it 'does not schedule next work' do
          expect(WorkOverseerTestWorker.jobs.count).to eq(0)
        end
      end
    end

    context 'worker with rekiq_cancel_method configured' do
      let(:worker) { WorkOverseerCancelTestWorker.new }
      let(:queue)  { WorkOverseerCancelTestWorker.get_sidekiq_options['queue'] }

      context 'msg with rq:ctr key (existing contract), ' \
              'with rq:sdl key (value is irrelevant), '   \
              'with rq:at key' do
        let(:msg) do
          {
            'rq:ctr' => contract.to_hash,
            'args'   => args,
            'rq:sdl' => nil,
            'rq:at'  => scheduled_work_time.to_f
          }
        end

        context 'work is cancelled by cancel method' do
          let(:cancel_args) { true }

          it 'does not yield' do
            expect do |b|
              overseer.call(worker, msg, queue, &b)
            end.not_to yield_control
          end

          it 'does not schedule next work' do
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
            expect(WorkOverseerCancelTestWorker.jobs.count).to eq(1)
          end

          it 'removes key rq:sdl from message after invocation' do
            expect(msg.key?('rq:sdl')).to eq(false)
          end

          it 'sets scheduled_work_time attribute in worker' do
            expect(worker.scheduled_work_time).to eq(scheduled_work_time.utc)
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