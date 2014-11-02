require 'spec_helper'

describe Rekiq::Scheduler do
  describe '#schedule_initial_work' do
    context 'given existing worker' do
      class SchedulerTestWorker
        include Sidekiq::Worker
      end

      let(:worker) { SchedulerTestWorker.new }
      let(:queue)  { 'test_queue' }
      let(:args)   { [] }
      let(:scheduler) do
        Rekiq::Scheduler.new(worker, queue, args, contract)
      end
      before { @jid, @work_time = scheduler.schedule_initial_work }

      context 'given valid contract' do
        let(:contract) { build :contract }

        context 'given nil as rekiq_cancel_args' do
          it 'creates sidekiq job' do
            expect(SchedulerTestWorker.jobs.count).to eq(1)
          end
        end
      end
    end
  end
end