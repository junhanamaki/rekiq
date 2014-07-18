require 'spec_helper'

describe Rekiq::Middleware::Utils do
  class UtilsTestWorker
    include Sidekiq::Worker
  end

  describe '#call' do
    let(:worker) { UtilsTestWorker.new }
    let(:queue)  { UtilsTestWorker.get_sidekiq_options['queue'] }
    let(:scheduled_work_time) { Time.at(Time.now.to_f) }

    context 'worker responds to scheduled_work_time' do
      context 'msg hash has rq:at key with value Time' do
        let(:msg) { { 'rq:at' => scheduled_work_time.to_f } }

        it 'yields passed block' do
          expect do |b|
            Rekiq::Middleware::Utils.new
              .call(worker, msg, queue, &b)
          end.to yield_control.once
        end

        it 'sets scheduled_work_time attribute in worker' do
          Rekiq::Middleware::Utils.new
            .call(worker, msg, queue) {}

          expect(worker.scheduled_work_time).to eq(scheduled_work_time.utc)
        end
      end

      context 'msg has no key' do
        let(:msg) { {} }

        it 'yields passed block' do
          expect do |b|
            Rekiq::Middleware::Utils.new
              .call(worker, msg, queue, &b)
          end.to yield_control.once
        end

        it 'scheduled_work_time remaing unchanged' do
          expect(worker.scheduled_work_time).to be_nil
        end
      end
    end
  end
end