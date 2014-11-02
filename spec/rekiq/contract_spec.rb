require 'spec_helper'

describe Rekiq::Contract, :t do
  describe '.new' do
    context 'when no args' do
      before { @contract = Rekiq::Contract.new }

      it 'returns an instance of Contract' do
        expect(@contract).not_to be_nil
      end

      it 'sets attribute work_time_shift as nil' do
        expect(@contract.work_time_shift).to eq(nil)
      end

      it 'sets schedule_post_work as nil' do
        expect(@contract.schedule_post_work).to eq(nil)
      end

      it 'sets schedule_expired as nil' do
        expect(@contract.schedule_expired).to eq(nil)
      end
    end

    context 'when work_time_shift passed as argument' do
      let(:work_time_shift) { 5 * 60 }
      before do
        @contract = Rekiq::Contract.new('work_time_shift' => work_time_shift)
      end

      it 'sets work_time_shift to passed value' do
        expect(@contract.work_time_shift).to eq(work_time_shift)
      end
    end

    context 'when schedule_post_work and ' \
            'schedule_expired passed as true' do
      let(:schedule_post_work) { true }
      let(:schedule_expired)   { true }
      before do
        @contract =
          Rekiq::Contract.new \
            'schedule_post_work' => schedule_post_work,
            'schedule_expired'   => schedule_expired
      end

      it 'sets schedule_post_work to true' do
        expect(@contract.schedule_post_work).to eq(true)
      end

      it 'sets schedule_expired to true' do
        expect(@contract.schedule_expired).to eq(true)
      end
    end
  end

  describe '.to_hash' do
    context 'given an hash returned from Contract#to_hash' do
      let(:original_contract) { build(:contract, :randomized_attributes) }
      let(:hash) { original_contract.to_hash }
      before     { @contract = Rekiq::Contract.from_hash(hash) }

      it 'returns contract instance' do
        expect(@contract.class).to eq(Rekiq::Contract)
      end

      it 'returns contract with cancel_args value before serialization' do
        expect(@contract.cancel_args).to eq(original_contract.cancel_args)
      end

      it 'returns contract with addon value before serialization' do
        expect(@contract.addon).to eq(original_contract.addon)
      end

      it 'returns contract with work_time_shift value before serialization' do
        expect(@contract.work_time_shift).to eq(original_contract.work_time_shift)
      end

      it 'returns contract with schedule_post_work value before serialization' do
        expect(@contract.schedule_post_work).to eq(original_contract.schedule_post_work)
      end

      it 'returns contract with schedule_expired value before serialization' do
        expect(@contract.schedule_expired).to eq(original_contract.schedule_expired)
      end

      it 'returns contract with work_time_tolerance value before serialization' do
        expect(@contract.work_time_tolerance).to eq(original_contract.work_time_tolerance)
      end

      it 'returns contract with schedule value before serialization' do
        expect(@contract.schedule.class).to eq(original_contract.schedule.class)
      end

      it 'returns contract with working schedule' do
        time = Time.now
        expect(@contract.schedule.next_occurrence(time))
          .to eq(original_contract.schedule.next_occurrence(time))
      end
    end
  end

  describe '#to_hash' do
    context 'given contract instance' do
      let(:contract) { build(:contract, :randomized_attributes) }
      before         { @val = contract.to_hash }

      it 'returns an hash' do
        expect(@val.class).to eq(Hash)
      end

      it 'returns hash with Marshalled schedule under key s' do
        # TODO: expect(@val[0]).to eq(Marshal.dump(contract.schedule))
      end

      it 'returns hash with cancel_args under key ca' do
        expect(@val['ca']).to eq(contract.cancel_args)
      end

      it 'returns hash with addon value under key ao' do
        expect(@val['ao']).to eq(contract.addon)
      end

      it 'returns hash with schedule_post_work value under key pw' do
        expect(@val['pw']).to eq(contract.schedule_post_work)
      end

      it 'returns hash with work_time_shift value under key ws' do
        expect(@val['ws']).to eq(contract.work_time_shift)
      end

      it 'returns hash with work_time_tolerance value under key wt' do
        expect(@val['wt']).to eq(contract.work_time_tolerance)
      end

      it 'returns hash with schedule_expired value under key se' do
        expect(@val['se']).to eq(contract.schedule_expired)
      end
    end
  end

  describe '#next_work_time' do
    context 'non recurring schedule in future' do
      let(:exceed_by)     { 10 * 60 }
      let(:schedule_time) { Time.now + exceed_by }
      let(:schedule)      { IceCube::Schedule.new(schedule_time) }

      context 'schedule expired as true' do
        let(:schedule_expired) { true }

        context 'calculating from current time' do
          let(:contract) do
            build(:contract, schedule: schedule, schedule_expired: schedule_expired)
          end
          before { @next_work_time = contract.next_work_time }

          it 'return schedule time' do
            expect(@next_work_time).to eq(schedule_time)
          end
        end

        context 'work_time_shift to time between current and schedule time' do
          let(:work_time_shift) { - exceed_by / 2 }

          context 'calculating from current time' do
            let(:contract) do
              build(:contract,
                    schedule: schedule,
                    schedule_expired: schedule_expired,
                    work_time_shift: work_time_shift)
            end
            before { @next_work_time = contract.next_work_time }

            it 'returns shifted schedule time' do
              expect(@next_work_time).to eq(schedule_time + work_time_shift)
            end
          end
        end

        context 'work_time_shift to time after schedule time' do
          let(:work_time_shift) { 60 }

          context 'calculating from current time' do
            let(:contract) do
              build(:contract,
                    schedule: schedule,
                    schedule_expired: schedule_expired,
                    work_time_shift:  work_time_shift)
            end
            before { @next_work_time = contract.next_work_time }

            it 'returns shifted schedule time' do
              expect(@next_work_time).to eq(schedule_time + work_time_shift)
            end
          end
        end

        context 'work_time_shift to time before current time' do
          let(:work_time_shift) { - (schedule_time - Time.now + 60) }

          context 'calculating from current time' do
            let(:contract) do
              build(:contract,
                    schedule: schedule,
                    schedule_expired: schedule_expired,
                    work_time_shift:  work_time_shift)
            end
            before { @next_work_time = contract.next_work_time }

            it 'returns shifted schedule time' do
              expect(@next_work_time).to eq(schedule_time + work_time_shift)
            end
          end
        end
      end

      context 'schedule expired as false' do
        let(:schedule_expired)  { false }
        let(:work_time_tolerance) { 10 * 60 }

        context 'calculating from current time' do
          let(:contract) do
            build(:contract, schedule: schedule,
                  schedule_expired: schedule_expired,
                  work_time_tolerance: work_time_tolerance)
          end
          before { @next_work_time = contract.next_work_time }

          it 'returns schedule time' do
            expect(@next_work_time).to eq(schedule_time)
          end
        end

        context 'work_time_shift to time between current and schedule time' do
          let(:work_time_shift) { - exceed_by / 2 }

          context 'calculating from current time' do
            let(:contract) do
              build(:contract, schedule: schedule,
                    schedule_expired: schedule_expired,
                    work_time_tolerance: work_time_tolerance,
                    work_time_shift: work_time_shift)
            end
            before { @next_work_time = contract.next_work_time }

            it 'returns shifted schedule time' do
              expect(@next_work_time).to eq(schedule_time + work_time_shift)
            end
          end
        end

        context 'work_time_shift to time after schedule time' do
          let(:work_time_shift) { 60 }

          context 'calculating from current time' do
            let(:contract) do
              build(:contract, schedule: schedule,
                    schedule_expired: schedule_expired,
                    work_time_tolerance: work_time_tolerance,
                    work_time_shift: work_time_shift)
            end
            before { @next_work_time = contract.next_work_time }

            it 'returns shifted schedule time' do
              expect(@next_work_time).to eq(schedule_time + work_time_shift)
            end
          end
        end

        context 'work_time_shift to time inside expired margin' do
          let(:work_time_shift) { - (schedule_time - Time.now + work_time_tolerance / 2) }

          context 'calculating from current time' do
            let(:contract) do
              build(:contract, schedule: schedule,
                    schedule_expired: schedule_expired,
                    work_time_tolerance: work_time_tolerance,
                    work_time_shift: work_time_shift)
            end
            before { @next_work_time = contract.next_work_time }

            it 'returns shifted schedule time' do
              expect(@next_work_time).to eq(schedule_time + work_time_shift)
            end
          end
        end

        context 'work_time_shift to time before expired margin' do
          let(:work_time_shift) { - (schedule_time - Time.now + work_time_tolerance * 2) }

          context 'calculating from current time' do
            let(:contract) do
              build(:contract, schedule: schedule,
                    schedule_expired: schedule_expired,
                    work_time_tolerance: work_time_tolerance,
                    work_time_shift: work_time_shift)
            end
            before { @next_work_time = contract.next_work_time }

            it 'returns nil' do
              expect(@next_work_time).to be_nil
            end
          end
        end
      end
    end

    context 'non recurring expired schedule' do
      let(:expired_by)    { 10 * 60 }
      let(:schedule_time) { Time.now - expired_by }
      let(:schedule)      { IceCube::Schedule.new(schedule_time) }

      context 'schedule expired as true' do
        let(:schedule_expired) { true }

        context 'calculating from current time' do
          let(:contract) do
              build(:contract, schedule: schedule,
                    schedule_expired: schedule_expired)
          end
          before { @next_work_time = contract.next_work_time }

          it 'returns nil' do
            expect(@next_work_time).to be_nil
          end
        end

        context 'calculating from before schedule time' do
          let(:from) { schedule_time - 60 }
          let(:contract) do
            build(:contract, schedule: schedule,
                  schedule_expired: schedule_expired)
          end
          before { @next_work_time = contract.next_work_time(from) }

          it 'returns schedule time' do
            expect(@next_work_time).to eq(schedule_time)
          end
        end

        context 'work_time_shift to after current time' do
          let(:work_time_shift) { expired_by * 2 }

          context 'calculating from current time' do
            let(:contract) do
              build(:contract, schedule: schedule,
                    schedule_expired: schedule_expired,
                    work_time_shift: work_time_shift)
            end
            before { @next_work_time = contract.next_work_time }

            it 'returns shifted schedule time' do
              expect(@next_work_time).to eq(schedule_time + work_time_shift)
            end
          end
        end
      end

      context 'schedule expired as false' do
        let(:schedule_expired) { false }

        context 'expiration margin as 0' do
          let(:work_time_tolerance) { 0 }

          context 'calculating from current time' do
            let(:contract) do
              build(:contract,
                    schedule: schedule,
                    schedule_expired: schedule_expired,
                    work_time_tolerance: work_time_tolerance)
            end
            before { @next_work_time = contract.next_work_time }

            it 'returns nil' do
              expect(@next_work_time).to be_nil
            end
          end
        end

        context 'expiration margin above expiration time' do
          let(:work_time_tolerance) { expired_by * 2 }

          context 'calculating from before schedule time' do
            let(:from) { schedule_time - work_time_tolerance - 60 }
            let(:contract) do
              build(:contract, schedule: schedule,
                    work_time_tolerance: work_time_tolerance,
                    schedule_expired: schedule_expired)
            end
            before { @next_work_time = contract.next_work_time(from) }

            it 'returns schedule time' do
              expect(@next_work_time).to eq(schedule_time)
            end
          end
        end

        context 'expiration margin above expiration time' do
          let(:work_time_tolerance) { expired_by / 2 }

          context 'calculating from before schedule time' do
            let(:from) { schedule_time - work_time_tolerance - 60 }
            let(:contract) do
              build(:contract, schedule: schedule,
                    work_time_tolerance: work_time_tolerance,
                    schedule_expired: schedule_expired)
            end
            before { @next_work_time = contract.next_work_time(from) }

            it 'returns nil' do
              expect(@next_work_time).to be_nil
            end
          end
        end
      end
    end
  end
end