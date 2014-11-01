require 'spec_helper'

describe Rekiq::Configuration do
  describe '.new' do
    context 'for created Configuration instance' do
      before { @configuration = Rekiq::Configuration.new }

      it 'sets work_time_shift as 0 by default' do
        expect(@configuration.work_time_shift).to eq(0)
      end

      it 'sets schedule_post_work as false by default' do
        expect(@configuration.schedule_post_work).to eq(false)
      end

      it 'sets work_time_tolerance as 0 by default' do
        expect(@configuration.work_time_tolerance).to eq(0)
      end

      it 'sets schedule_expired as false by default' do
        expect(@configuration.schedule_expired).to eq(false)
      end
    end
  end

  describe '#validate!' do
    context 'for instance with non numeric work_time_shift' do
      before { @configuration = build(:configuration, work_time_shift: [1]) }

      it 'raises error' do
        expect do
          @configuration.validate!
        end.to raise_error
      end
    end

    context 'for instance with numeric work_time_shift' do
      before { @configuration = build(:configuration) }

      it 'does not raise error' do
        expect do
          @configuration.validate!
        end.not_to raise_error
      end
    end

    context 'for instance with non bool schedule_post_work' do
      before do
        @configuration = build(:configuration, schedule_post_work: 'true')
      end

      it 'raises error' do
        expect do
          @configuration.validate!
        end.to raise_error
      end
    end

    context 'for instance with bool schedule_post_work' do
      before { @configuration = build(:configuration) }

      it 'does not raise error' do
        expect do
          @configuration.validate!
        end.not_to raise_error
      end
    end

    context 'for instance with non numeric work_time_tolerance' do
      before { @configuration = build(:configuration, work_time_tolerance: '1') }

      it 'raises error' do
        expect do
          @configuration.validate!
        end.to raise_error
      end
    end

    context 'for instance with negative work_time_tolerance' do
      before { @configuration = build(:configuration, work_time_tolerance: -1) }

      it 'raises error' do
        expect do
          @configuration.validate!
        end.to raise_error
      end
    end

    context 'for instance with 0 or positive work_time_tolerance' do
      before { @configuration = build(:configuration) }

      it 'does not raise error' do
        expect do
          @configuration.validate!
        end.not_to raise_error
      end
    end

    context 'for instance with non bool schedule_expired' do
      before do
        @configuration = build(:configuration, schedule_expired: 'false')
      end

      it 'raises error' do
        expect do
          @configuration.validate!
        end.to raise_error
      end
    end

    context 'for instance with bool schedule_expired' do
      before { @configuration = build(:configuration) }

      it 'does not raise error' do
        expect do
          @configuration.validate!
        end.not_to raise_error
      end
    end
  end
end