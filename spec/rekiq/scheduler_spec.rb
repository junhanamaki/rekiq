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

      context 'given valid job' do
        let(:job) { build(:job) }

        context 'given not nil string as add_on argument' do
          let(:add_on) { { 'random_key' => Time.now.to_f } }

          context 'given initialized scheduler instance' do
            let(:scheduler) do
              Rekiq::Scheduler.new(worker, queue, args, job, add_on)
            end
            before { @jid, @work_time = scheduler.schedule }

            it 'creates sidekiq job' do
              expect(SchedulerTestWorker.jobs.count).to eq(1)
            end

            it 'add key add_on to msg' do
              expect(SchedulerTestWorker.jobs[0].key?('add_on')).to eq(true)
            end

            it 'sets add_on value in worker msg' do
              expect(SchedulerTestWorker.jobs[0]['add_on']).to eq(add_on)
            end
          end
        end

        context 'give nil as add_on argument' do
          let(:add_on) { nil }

          context 'given initialized scheduler instance' do
            let(:scheduler) do
              Rekiq::Scheduler.new(worker, queue, args, job, add_on)
            end
            before { @jid, @work_time = scheduler.schedule }

            it 'creates sidekiq job' do
              expect(SchedulerTestWorker.jobs.count).to eq(1)
            end

            it 'does not set key add_on in msg' do
              expect(SchedulerTestWorker.jobs[0].key?('add_on')).to eq(false)
            end
          end
        end
      end
    end
  end
end