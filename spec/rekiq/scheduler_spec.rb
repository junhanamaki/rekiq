require 'spec_helper'

describe Rekiq::Scheduler do
  describe '#schedule' do
    context 'given existing worker' do
      class SchedulerTestWorker
        include Sidekiq::Worker
      end

      let(:worker) { SchedulerTestWorker.name }
      let(:queue)  { 'test_queue' }
      let(:args)   { [] }
      let(:c_args) { nil }

      context 'given valid job' do
        let(:job) { build(:job) }

        context 'given not nil string as addon argument' do
          let(:addon) { { 'random_key' => Time.now.to_f } }

          context 'given initialized scheduler instance' do
            let(:scheduler) do
              Rekiq::Scheduler.new(worker, queue, args, job, addon, c_args)
            end
            before { @jid, @work_time = scheduler.schedule }

            it 'creates sidekiq job' do
              expect(SchedulerTestWorker.jobs.count).to eq(1)
            end

            it 'add key rq:addon in msg' do
              expect(SchedulerTestWorker.jobs[0].key?('rq:addon')).to eq(true)
            end

            it 'sets addon value in key rq:addon' do
              expect(SchedulerTestWorker.jobs[0]['rq:addon']).to eq(addon)
            end
          end
        end

        context 'give nil as addon argument' do
          let(:addon) { nil }

          context 'given initialized scheduler instance' do
            let(:scheduler) do
              Rekiq::Scheduler.new(worker, queue, args, job, addon, c_args)
            end
            before { @jid, @work_time = scheduler.schedule }

            it 'creates sidekiq job' do
              expect(SchedulerTestWorker.jobs.count).to eq(1)
            end

            it 'does not set key addon in msg' do
              expect(SchedulerTestWorker.jobs[0].key?('addon')).to eq(false)
            end
          end
        end
      end
    end
  end
end