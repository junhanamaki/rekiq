module Rekiq
  class Scheduler
    attr_accessor :worker_name, :queue, :args, :job, :add_on, :work_time

    def initialize(worker_name, queue, args, job, add_on)
      self.worker_name = worker_name
      self.queue       = queue
      self.args        = args
      self.job         = job
      self.add_on      = add_on
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
          'at'    => work_time.to_f,
          'queue' => queue,
          'class' => worker_name,
          'args'  => args,
          'scheduled_work_time' => work_time.to_f,
          'mandragora:job'      => job.to_hash
        }.tap do |hash|
          hash['add_on'] = add_on unless add_on.nil?
        end

      Sidekiq::Client.push(client_args)
    end
  end
end