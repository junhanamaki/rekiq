require 'spec_helper'

describe Rekiq::Middleware::WorkOverseer do
  class WorkOverseerTestWorker
    include Sidekiq::Worker

    sidekiq_options queue: 'work_overseer_test_worker'
  end

  class WorkOverseerCancelTestWorker
    include Sidekiq::Worker

    sidekiq_options queue: 'work_overseer_test_worker'
    rekiq_canceller :cancel

    def cancel(bool)
      bool
    end
  end

  describe '#call' do
    let(:args)     { [] }
    let(:schedule) { IceCube::Schedule.new(Time.new + 3600) }
    let(:job)      { build(:job, schedule: schedule) }
    let(:overseer) { Rekiq::Middleware::WorkOverseer.new }

    context 'worker does not have rekiq_canceller set' do
      let(:worker)   { WorkOverseerTestWorker.new }
      let(:queue)    { WorkOverseerTestWorker.get_sidekiq_options['queue'] }

      context 'msg with rq:job key (existing job)' do
        let(:msg) { { 'rq:job' => job.to_array, 'args' => args } }

        it 'yields once' do
          expect do |b|
            overseer.call(worker, msg, queue, &b)
          end.to yield_control.once
        end

        it 'schedules job' do
          overseer.call(worker, msg, queue) {}

          expect(WorkOverseerTestWorker.jobs.count).to eq(1)
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

      context 'msg with job retry info and rq:job (existing job)' do
        let(:msg) { { 'rq:job' => job.to_array, 'retry_count' => 0,
                      'args' => args } }

        it 'yields once' do
          expect do |b|
            overseer.call(worker, msg, queue, &b)
          end.to yield_control.once
        end

        it 'does not schedule work' do
          overseer.call(worker, msg, queue) {}

          expect(WorkOverseerTestWorker.jobs.count).to eq(0)
        end
      end
    end

    context 'worker has rekiq_canceller method set' do
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

        it 'does not scheduler worker' do
          expect(WorkOverseerCancelTestWorker.jobs.count).to eq(0)
        end
      end

      context 'msg with rq:ca key with value that does not cancel worker' do
        let(:msg) do
          { 'rq:job' => job.to_array, 'args' => args, 'rq:ca' => false }
        end

        it 'does yield' do
          expect do |b|
            overseer.call(worker, msg, queue, &b)
          end.to yield_control.once
        end
      end
    end
  end
end