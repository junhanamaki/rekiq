require 'spec_helper'

describe Rekiq::Job do
  describe '#new' do
    context 'when no args' do
      before { @job = Rekiq::Job.new }

      it 'returns an instance of Job' do
        expect(@job).not_to be_nil
      end

      it 'sets attribute shift as 0' do
        expect(@job.shift).to eq(0)
      end

      it 'sets schedule_post_work as nil' do
        expect(@job.schedule_post_work).to eq(nil)
      end

      it 'sets schedule_expired as nil' do
        expect(@job.schedule_expired).to eq(nil)
      end
    end

    context 'when shift passed as argument' do
      let(:shift) { 5 * 60 }
      before do
        @job = Rekiq::Job.new('shift' => shift)
      end

      it 'sets shift to passed value' do
        expect(@job.shift).to eq(shift)
      end
    end

    context 'when schedule_post_work and ' \
            'schedule_expired passed as true' do
      let(:schedule_post_work) { true }
      let(:schedule_expired) { true }
      before do
        @job =
          Rekiq::Job.new \
            'schedule_post_work' => schedule_post_work,
            'schedule_expired'     => schedule_expired
      end

      it 'sets schedule_post_work to true' do
        expect(@job.schedule_post_work).to eq(true)
      end

      it 'sets schedule_expired to true' do
        expect(@job.schedule_expired).to eq(true)
      end
    end
  end

  describe '#from_short_key_hash' do
    context 'hash returned from Job#to_short_key_hash' do
      let(:job)  { build(:job, :randomized_attributes) }
      let(:hash) { job.to_short_key_hash }
      before     { @job = Rekiq::Job.from_short_key_hash(hash) }

      it 'returns job instance' do
        expect(@job.class).to eq(Rekiq::Job)
      end

      it 'returns job with shift value before serialization' do
        expect(@job.shift).to eq(job.shift)
      end

      it 'returns job with schedule_post_work value before serialization' do
        expect(@job.schedule_post_work).to eq(job.schedule_post_work)
      end

      it 'returns job with schedule_expired value before serialization' do
        expect(@job.schedule_expired).to eq(job.schedule_expired)
      end

      it 'returns job with expiration_margin value before serialization' do
        expect(@job.expiration_margin).to eq(job.expiration_margin)
      end

      it 'returns job with schedule value before serialization' do
        expect(@job.schedule.class).to eq(job.schedule.class)
      end

      it 'returns job with working schedule' do
        time = Time.now
        expect(@job.schedule.next_occurrence(time)).to(
          eq(job.schedule.next_occurrence(time))
        )
      end
    end
  end

  describe '.to_short_key_hash' do
    context 'given job instance' do
      let(:job) { build(:job, :randomized_attributes) }
      before { @val = job.to_short_key_hash }

      it 'returns an hash' do
        expect(@val.class).to eq(Hash)
      end

      it 'returns hash with key sft with shift value' do
        expect(@val['sft']).to eq(job.shift)
      end

      it 'returns hash with key spw with schedule_post_work value' do
        expect(@val['spw']).to eq(job.schedule_post_work)
      end

      it 'returns hash with key sh with schedule_expired value' do
        expect(@val['se']).to eq(job.schedule_expired)
      end

      it 'returns hash with key em with expiration_margin value' do
        expect(@val['em']).to eq(job.expiration_margin)
      end

      it 'returns hash with sch key with schedule serialized with YAML::dump' do
        expect(@val['sch']).to eq(YAML::dump(job.schedule))
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
          let(:job) do
            build(:job, schedule: schedule, schedule_expired: schedule_expired)
          end
          before { @next_work_time = job.next_work_time }

          it 'return schedule time' do
            expect(@next_work_time).to eq(schedule_time)
          end
        end

        context 'shift to time between current and schedule time' do
          let(:shift) { - exceed_by / 2 }

          context 'calculating from current time' do
            let(:job) do
              build(:job,
                    schedule: schedule,
                    schedule_expired: schedule_expired,
                    shift: shift)
            end
            before { @next_work_time = job.next_work_time }

            it 'returns shifted schedule time' do
              expect(@next_work_time).to eq(schedule_time + shift)
            end
          end
        end

        context 'shift to time after schedule time' do
          let(:shift) { 60 }

          context 'calculating from current time' do
            let(:job) do
              build(:job, schedule: schedule,
                    schedule_expired: schedule_expired,
                    shift: shift)
            end
            before { @next_work_time = job.next_work_time }

            it 'returns shifted schedule time' do
              expect(@next_work_time).to eq(schedule_time + shift)
            end
          end
        end

        context 'shift to time before current time' do
          let(:shift) { - (schedule_time - Time.now + 60) }

          context 'calculating from current time' do
            let(:job) do
              build(:job, schedule: schedule,
                    schedule_expired: schedule_expired,
                    shift: shift)
            end
            before { @next_work_time = job.next_work_time }

            it 'returns shifted schedule time' do
              expect(@next_work_time).to eq(schedule_time + shift)
            end
          end
        end
      end

      context 'schedule expired as false' do
        let(:schedule_expired)  { false }
        let(:expiration_margin) { 10 * 60 }

        context 'calculating from current time' do
          let(:job) do
            build(:job, schedule: schedule,
                  schedule_expired: schedule_expired,
                  expiration_margin: expiration_margin)
          end
          before { @next_work_time = job.next_work_time }

          it 'returns schedule time' do
            expect(@next_work_time).to eq(schedule_time)
          end
        end

        context 'shift to time between current and schedule time' do
          let(:shift) { - exceed_by / 2 }

          context 'calculating from current time' do
            let(:job) do
              build(:job, schedule: schedule,
                    schedule_expired: schedule_expired,
                    expiration_margin: expiration_margin,
                    shift: shift)
            end
            before { @next_work_time = job.next_work_time }

            it 'returns shifted schedule time' do
              expect(@next_work_time).to eq(schedule_time + shift)
            end
          end
        end

        context 'shift to time after schedule time' do
          let(:shift) { 60 }

          context 'calculating from current time' do
            let(:job) do
              build(:job, schedule: schedule,
                    schedule_expired: schedule_expired,
                    expiration_margin: expiration_margin,
                    shift: shift)
            end
            before { @next_work_time = job.next_work_time }

            it 'returns shifted schedule time' do
              expect(@next_work_time).to eq(schedule_time + shift)
            end
          end
        end

        context 'shift to time inside expired margin' do
          let(:shift) { - (schedule_time - Time.now + expiration_margin / 2) }

          context 'calculating from current time' do
            let(:job) do
              build(:job, schedule: schedule,
                    schedule_expired: schedule_expired,
                    expiration_margin: expiration_margin,
                    shift: shift)
            end
            before { @next_work_time = job.next_work_time }

            it 'returns shifted schedule time' do
              expect(@next_work_time).to eq(schedule_time + shift)
            end
          end
        end

        context 'shift to time before expired margin' do
          let(:shift) { - (schedule_time - Time.now + expiration_margin * 2) }

          context 'calculating from current time' do
            let(:job) do
              build(:job, schedule: schedule,
                    schedule_expired: schedule_expired,
                    expiration_margin: expiration_margin,
                    shift: shift)
            end
            before { @next_work_time = job.next_work_time }

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
          let(:job) do
              build(:job, schedule: schedule,
                    schedule_expired: schedule_expired)
          end
          before { @next_work_time = job.next_work_time }

          it 'returns nil' do
            expect(@next_work_time).to be_nil
          end
        end

        context 'calculating from before schedule time' do
          let(:from) { schedule_time - 60 }
          let(:job) do
            build(:job, schedule: schedule,
                  schedule_expired: schedule_expired)
          end
          before { @next_work_time = job.next_work_time(from) }

          it 'returns schedule time' do
            expect(@next_work_time).to eq(schedule_time)
          end
        end

        context 'shift to after current time' do
          let(:shift) { expired_by * 2 }

          context 'calculating from current time' do
            let(:job) do
              build(:job, schedule: schedule,
                    schedule_expired: schedule_expired,
                    shift: shift)
            end
            before { @next_work_time = job.next_work_time }

            it 'returns shifted schedule time' do
              expect(@next_work_time).to eq(schedule_time + shift)
            end
          end
        end
      end

      context 'schedule expired as false' do
        let(:schedule_expired) { false }

        context 'expiration margin as 0' do
          let(:expiration_margin) { 0 }

          context 'calculating from current time' do
            let(:job) do
              build(:job, schedule: schedule,
                    schedule_expired: schedule_expired,
                    expiration_margin: expiration_margin)
            end
            before { @next_work_time = job.next_work_time }

            it 'returns nil' do
              expect(@next_work_time).to be_nil
            end
          end
        end

        context 'expiration margin above expiration time' do
          let(:expiration_margin) { expired_by * 2 }

          context 'calculating from before schedule time' do
            let(:from) { schedule_time - expiration_margin - 60 }
            let(:job) do
              build(:job, schedule: schedule,
                    expiration_margin: expiration_margin,
                    schedule_expired: schedule_expired)
            end
            before { @next_work_time = job.next_work_time(from) }

            it 'returns schedule time' do
              expect(@next_work_time).to eq(schedule_time)
            end
          end
        end

        context 'expiration margin above expiration time' do
          let(:expiration_margin) { expired_by / 2 }

          context 'calculating from before schedule time' do
            let(:from) { schedule_time - expiration_margin - 60 }
            let(:job) do
              build(:job, schedule: schedule,
                    expiration_margin: expiration_margin,
                    schedule_expired: schedule_expired)
            end
            before { @next_work_time = job.next_work_time(from) }

            it 'returns nil' do
              expect(@next_work_time).to be_nil
            end
          end
        end
      end
    end
  end
end