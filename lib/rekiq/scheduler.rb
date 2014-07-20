module Rekiq
  class Scheduler
    attr_accessor :worker_name, :queue, :args, :job, :addon, :work_time,
                  :canceler_args

    def initialize(worker_name, queue, args, job, addon, canceler_args)
      self.worker_name = worker_name
      self.queue       = queue
      self.args        = args
      self.job         = job
      self.addon       = addon
      self.canceler_args = canceler_args
    end

    def schedule(from = Time.now)
      self.work_time = job.next_work_time(from)

      work_time.nil? ? nil : [schedule_work, work_time]
    end

    def schedule_from_work_time(from)
      self.work_time = job.next_work_time_from_work_time(from)

      work_time.nil? ? nil : [schedule_work, work_time]
    end

  private

    def schedule_work
      client_args = {
          'at'     => work_time.to_f,
          'queue'  => queue,
          'class'  => worker_name,
          'args'   => args,
          'rq:job' => job.to_array,
          'rq:at'  => work_time.to_f,
        }.tap do |hash|
          hash['rq:addon'] = addon unless addon.nil?
          hash['rq:ca']    = canceler_args unless canceler_args.nil?
        end

      Sidekiq::Client.push(client_args)
    end
  end
end