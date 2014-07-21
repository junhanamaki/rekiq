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
      let(:addon)  { nil }
      let(:c_args) { nil }
      let(:scheduler) do
        Rekiq::Scheduler.new(worker, queue, args, job, addon, c_args)
      end
      before { @jid, @work_time = scheduler.schedule }

      context 'given valid job' do
        let(:job) { build(:job) }

        context 'give nil as addon argument' do
          it 'creates sidekiq job' do
            expect(SchedulerTestWorker.jobs.count).to eq(1)
          end

          it 'does not set key rq:addon in msg' do
            expect(SchedulerTestWorker.jobs[0].key?('rq:addon')).to eq(false)
          end
        end

        context 'given not nil string as addon argument' do
          let(:addon) { { 'random_key' => Time.now.to_f } }

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

        context 'given nil as canceller_args' do
          it 'creates sidekiq job' do
            expect(SchedulerTestWorker.jobs.count).to eq(1)
          end

          it 'does not set key rq:ca in msg' do
            expect(SchedulerTestWorker.jobs[0].key?('rq:ca')).to eq(false)
          end
        end

        context 'given non empty array as canceller_args' do
          let(:c_args) { [1, 2, 3] }

          it 'creates sidekiq job' do
            expect(SchedulerTestWorker.jobs.count).to eq(1)
          end

          it 'sets key rq:ca in msg' do
            expect(SchedulerTestWorker.jobs[0].key?('rq:ca')).to eq(true)
          end

          it 'sets key rq:ca in msg with passed value' do
            expect(SchedulerTestWorker.jobs[0]['rq:ca']).to eq(c_args)
          end
        end
      end
    end
  end
end