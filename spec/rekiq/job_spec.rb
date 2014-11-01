require 'spec_helper'

describe Rekiq::Job do
  describe '.new' do
    context 'when no args' do
      before { @job = Rekiq::Job.new }

      it 'returns an instance of Job' do
        expect(@job).not_to be_nil
      end

      it 'sets attribute work_time_shift as nil' do
        expect(@job.work_time_shift).to eq(nil)
      end

      it 'sets schedule_post_work as nil' do
        expect(@job.schedule_post_work).to eq(nil)
      end

      it 'sets schedule_expired as nil' do
        expect(@job.schedule_expired).to eq(nil)
      end
    end

    context 'when work_time_shift passed as argument' do
      let(:work_time_shift) { 5 * 60 }
      before do
        @job = Rekiq::Job.new('work_time_shift' => work_time_shift)
      end

      it 'sets work_time_shift to passed value' do
        expect(@job.work_time_shift).to eq(work_time_shift)
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
            'schedule_expired'   => schedule_expired
      end

      it 'sets schedule_post_work to true' do
        expect(@job.schedule_post_work).to eq(true)
      end

      it 'sets schedule_expired to true' do
        expect(@job.schedule_expired).to eq(true)
      end
    end
  end

  describe '.from_array' do
    context 'array returned from Job#to_array' do
      let(:job)   { build(:job, :randomized_attributes) }
      let(:array) { job.to_array }
      before      { @job = Rekiq::Job.from_array(array) }

      it 'returns job instance' do
        expect(@job.class).to eq(Rekiq::Job)
      end

      it 'returns job with work_time_shift value before serialization' do
        expect(@job.work_time_shift).to eq(job.work_time_shift)
      end

      it 'returns job with schedule_post_work value before serialization' do
        expect(@job.schedule_post_work).to eq(job.schedule_post_work)
      end

      it 'returns job with schedule_expired value before serialization' do
        expect(@job.schedule_expired).to eq(job.schedule_expired)
      end

      it 'returns job with work_time_tolerance value before serialization' do
        expect(@job.work_time_tolerance).to eq(job.work_time_tolerance)
      end

      it 'returns job with schedule value before serialization' do
        expect(@job.schedule.class).to eq(job.schedule.class)
      end

      it 'returns job with working schedule' do
        time = Time.now
        expect(@job.schedule.next_occurrence(time))
          .to eq(job.schedule.next_occurrence(time))
      end
    end
  end

  describe '#to_array' do
    context 'given job instance' do
      let(:job) { build(:job, :randomized_attributes) }
      before { @val = job.to_array }

      it 'returns an array' do
        expect(@val.class).to eq(Array)
      end

      it 'returns array with Marshalled object value at index 0' do
        # TODO: expect(@val[0]).to eq(Marshal.dump(job.schedule))
      end

      it 'returns array with work_time_shift value at index 1' do
        expect(@val[1]).to eq(job.work_time_shift)
      end

      it 'returns array with schedule_post_work value at index 2' do
        expect(@val[2]).to eq(job.schedule_post_work)
      end

      it 'returns array with schedule_expired value at index 3' do
        expect(@val[3]).to eq(job.schedule_expired)
      end

      it 'returns array with work_time_tolerance value at index 4' do
        expect(@val[4]).to eq(job.work_time_tolerance)
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

        context 'work_time_shift to time between current and schedule time' do
          let(:work_time_shift) { - exceed_by / 2 }

          context 'calculating from current time' do
            let(:job) do
              build(:job,
                    schedule: schedule,
                    schedule_expired: schedule_expired,
                    work_time_shift: work_time_shift)
            end
            before { @next_work_time = job.next_work_time }

            it 'returns shifted schedule time' do
              expect(@next_work_time).to eq(schedule_time + work_time_shift)
            end
          end
        end

        context 'work_time_shift to time after schedule time' do
          let(:work_time_shift) { 60 }

          context 'calculating from current time' do
            let(:job) do
              build(:job, schedule: schedule,
                    schedule_expired: schedule_expired,
                    work_time_shift: work_time_shift)
            end
            before { @next_work_time = job.next_work_time }

            it 'returns shifted schedule time' do
              expect(@next_work_time).to eq(schedule_time + work_time_shift)
            end
          end
        end

        context 'work_time_shift to time before current time' do
          let(:work_time_shift) { - (schedule_time - Time.now + 60) }

          context 'calculating from current time' do
            let(:job) do
              build(:job, schedule: schedule,
                    schedule_expired: schedule_expired,
                    work_time_shift: work_time_shift)
            end
            before { @next_work_time = job.next_work_time }

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
          let(:job) do
            build(:job, schedule: schedule,
                  schedule_expired: schedule_expired,
                  work_time_tolerance: work_time_tolerance)
          end
          before { @next_work_time = job.next_work_time }

          it 'returns schedule time' do
            expect(@next_work_time).to eq(schedule_time)
          end
        end

        context 'work_time_shift to time between current and schedule time' do
          let(:work_time_shift) { - exceed_by / 2 }

          context 'calculating from current time' do
            let(:job) do
              build(:job, schedule: schedule,
                    schedule_expired: schedule_expired,
                    work_time_tolerance: work_time_tolerance,
                    work_time_shift: work_time_shift)
            end
            before { @next_work_time = job.next_work_time }

            it 'returns shifted schedule time' do
              expect(@next_work_time).to eq(schedule_time + work_time_shift)
            end
          end
        end

        context 'work_time_shift to time after schedule time' do
          let(:work_time_shift) { 60 }

          context 'calculating from current time' do
            let(:job) do
              build(:job, schedule: schedule,
                    schedule_expired: schedule_expired,
                    work_time_tolerance: work_time_tolerance,
                    work_time_shift: work_time_shift)
            end
            before { @next_work_time = job.next_work_time }

            it 'returns shifted schedule time' do
              expect(@next_work_time).to eq(schedule_time + work_time_shift)
            end
          end
        end

        context 'work_time_shift to time inside expired margin' do
          let(:work_time_shift) { - (schedule_time - Time.now + work_time_tolerance / 2) }

          context 'calculating from current time' do
            let(:job) do
              build(:job, schedule: schedule,
                    schedule_expired: schedule_expired,
                    work_time_tolerance: work_time_tolerance,
                    work_time_shift: work_time_shift)
            end
            before { @next_work_time = job.next_work_time }

            it 'returns shifted schedule time' do
              expect(@next_work_time).to eq(schedule_time + work_time_shift)
            end
          end
        end

        context 'work_time_shift to time before expired margin' do
          let(:work_time_shift) { - (schedule_time - Time.now + work_time_tolerance * 2) }

          context 'calculating from current time' do
            let(:job) do
              build(:job, schedule: schedule,
                    schedule_expired: schedule_expired,
                    work_time_tolerance: work_time_tolerance,
                    work_time_shift: work_time_shift)
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

        context 'work_time_shift to after current time' do
          let(:work_time_shift) { expired_by * 2 }

          context 'calculating from current time' do
            let(:job) do
              build(:job, schedule: schedule,
                    schedule_expired: schedule_expired,
                    work_time_shift: work_time_shift)
            end
            before { @next_work_time = job.next_work_time }

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
            let(:job) do
              build(:job, schedule: schedule,
                    schedule_expired: schedule_expired,
                    work_time_tolerance: work_time_tolerance)
            end
            before { @next_work_time = job.next_work_time }

            it 'returns nil' do
              expect(@next_work_time).to be_nil
            end
          end
        end

        context 'expiration margin above expiration time' do
          let(:work_time_tolerance) { expired_by * 2 }

          context 'calculating from before schedule time' do
            let(:from) { schedule_time - work_time_tolerance - 60 }
            let(:job) do
              build(:job, schedule: schedule,
                    work_time_tolerance: work_time_tolerance,
                    schedule_expired: schedule_expired)
            end
            before { @next_work_time = job.next_work_time(from) }

            it 'returns schedule time' do
              expect(@next_work_time).to eq(schedule_time)
            end
          end
        end

        context 'expiration margin above expiration time' do
          let(:work_time_tolerance) { expired_by / 2 }

          context 'calculating from before schedule time' do
            let(:from) { schedule_time - work_time_tolerance - 60 }
            let(:job) do
              build(:job, schedule: schedule,
                    work_time_tolerance: work_time_tolerance,
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