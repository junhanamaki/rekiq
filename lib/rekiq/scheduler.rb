module Rekiq
  class Scheduler
    def initialize(worker_name, queue, args, job, addon, canceller_args)
      @worker_name = worker_name
      @queue       = queue
      @args        = args
      @job         = job
      @addon       = addon
      @canceller_args = canceller_args
    end

    def schedule(from = Time.now)
      @work_time = @job.next_work_time(from)

      @work_time.nil? ? nil : [schedule_work, @work_time]
    end

    def schedule_from_work_time(from)
      @work_time = @job.next_work_time_from_work_time(from)

      @work_time.nil? ? nil : [schedule_work, @work_time]
    end

  private

    def schedule_work
      client_args = {
          'at'     => @work_time.to_f,
          'queue'  => @queue,
          'class'  => @worker_name,
          'args'   => @args,
          'rq:job' => @job.to_array,
          'rq:at'  => @work_time.to_f,
        }.tap do |hash|
          hash['rq:addon'] = @addon unless @addon.nil?
          hash['rq:ca']    = @canceller_args unless @canceller_args.nil?
        end

      Sidekiq::Client.push(client_args)
    end
  end
end