require 'spec_helper'

describe Rekiq::Middleware::WorkOverseer do
  class WorkOverseerTestWorker
    include Sidekiq::Worker

    sidekiq_options queue: 'work_overseer_test_worker'
  end

  describe '#call' do
    let(:worker)   { WorkOverseerTestWorker.new }
    let(:queue)    { WorkOverseerTestWorker.get_sidekiq_options['queue'] }
    let(:args)     { [] }
    let(:schedule) { IceCube::Schedule.new(Time.new + 3600) }

    context 'msg with rq:job key (existing job)' do
      let(:job) { build(:job, schedule: schedule) }
      let(:msg) { { 'rq:job' => job.to_array, 'args' => args } }

      it 'yields once' do
        expect do |b|
          Rekiq::Middleware::WorkOverseer.new
            .call(worker, msg, queue, &b)
        end.to yield_control.once
      end

      it 'schedules job' do
        Rekiq::Middleware::WorkOverseer.new
          .call(worker, msg, queue) {}

        expect(WorkOverseerTestWorker.jobs.count).to eq(1)
      end
    end

    context 'msg without rq:job key' do
      let(:msg) { {} }

      it 'yields once' do
        expect do |b|
          Rekiq::Middleware::WorkOverseer.new
            .call(worker, msg, queue, &b)
        end.to yield_control.once
      end
    end

    context 'msg with job retry info and rq:job (existing job)' do
      let(:job) { build(:job, schedule: schedule) }
      let(:msg) { { 'rq:job' => job.to_array, 'retry_count' => 0,
                    'args' => args } }

      it 'yields once' do
        expect do |b|
          Rekiq::Middleware::WorkOverseer.new
            .call(worker, msg, queue, &b)
        end.to yield_control.once
      end

      it 'does not schedule work' do
        Rekiq::Middleware::WorkOverseer.new
          .call(worker, msg, queue) {}

        expect(WorkOverseerTestWorker.jobs.count).to eq(0)
      end
    end
  end
end