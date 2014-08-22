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
    let(:args)     { [] }
    let(:schedule) { IceCube::Schedule.new(Time.new + 3600) }
    let(:job)      { build(:job, schedule: schedule) }
    let(:overseer) { Rekiq::Middleware::WorkOverseer.new }

    context 'worker does not have rekiq_cancel_method set' do
      let(:worker)   { WorkOverseerTestWorker.new }
      let(:queue)    { WorkOverseerTestWorker.get_sidekiq_options['queue'] }

      context 'msg with rq:job key (existing job), ' \
              'with rq:schdlr key (value is irrelevant)' do
        let(:msg) do
          { 'rq:job' => job.to_array, 'args' => args, 'rq:schdlr' => nil }
        end

        it 'yields once' do
          expect do |b|
            overseer.call(worker, msg, queue, &b)
          end.to yield_control.once
        end

        it 'schedules job' do
          overseer.call(worker, msg, queue) {}

          expect(WorkOverseerTestWorker.jobs.count).to eq(1)
        end

        it 'removes key rq:schdlr from message after invocation' do
          overseer.call(worker, msg, queue) {}

          expect(msg.key?('rq:schdlr')).to eq(false)
        end
      end

      context 'msg without rq:job key' do
        let(:msg) { {} }

        it 'yields once' do
          expect do |b|
            overseer.call(worker, msg, queue, &b)
          end.to yield_control.once
        end
      end

      context 'msg without rq:schdlr and rq:job (existing job)' do
        let(:msg) { { 'rq:job' => job.to_array, 'args' => args } }

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

    context 'worker has rekiq_cancel_method method set' do
      let(:worker) { WorkOverseerCancelTestWorker.new }
      let(:queue)  { WorkOverseerCancelTestWorker.get_sidekiq_options['queue'] }

      context 'msg with rq:ca key with value to cancel worker' do
        let(:msg) do
          { 'rq:job' => job.to_array, 'args' => args, 'rq:ca' => true }
        end

        it 'does not yield' do
          expect do |b|
            overseer.call(worker, msg, queue, &b)
          end.not_to yield_control
        end

        it 'does not schedule worker' do
          expect(WorkOverseerCancelTestWorker.jobs.count).to eq(0)
        end
      end

      context 'msg with rq:ca key with value that does not cancel worker' do
        let(:msg) do
          { 'rq:job' => job.to_array, 'args' => args, 'rq:ca' => false }
        end

        it 'yields given block' do
          expect do |b|
            overseer.call(worker, msg, queue, &b)
          end.to yield_control.once
        end

        it 'does not schedule worker' do
          expect(WorkOverseerCancelTestWorker.jobs.count).to eq(0)
        end
      end

      context 'msg with rq:ca key with different arity from cancel method' do
        let(:msg) do
          { 'rq:job' => job.to_array, 'args' => args, 'rq:ca' => [true, true] }
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