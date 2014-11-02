require 'spec_helper'

describe Rekiq::Scheduler, :t do
  describe '#schedule_worker' do
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
        Rekiq::Scheduler.new(worker, queue, args, contract)
      end
      before { @jid, @work_time = scheduler.schedule_worker }

      context 'given valid contract' do
        let(:contract) { build :contract }

        context 'given nil as rekiq_cancel_args' do
          it 'creates sidekiq job' do
            expect(SchedulerTestWorker.jobs.count).to eq(1)
          end

          it 'does not set key rq:ca in msg' do
            expect(SchedulerTestWorker.jobs[0].key?('rq:ca')).to eq(false)
          end
        end
      end
    end
  end
end