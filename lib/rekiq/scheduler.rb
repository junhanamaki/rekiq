module Rekiq
  class Scheduler
    def initialize(worker_name, queue, args, contract)
      @worker_name = worker_name
      @queue       = queue
      @args        = args
      @contract    = contract
    end

    def schedule(from = Time.now)
      @work_time = @contract.next_work_time(from)

      @work_time.nil? ? nil : [schedule_work, @work_time]
    end

    def schedule_from_work_time(from)
      @work_time = @contract.next_work_time_from_work_time(from)

      @work_time.nil? ? nil : [schedule_work, @work_time]
    end

  protected

    def schedule_work
      client_args = {
        'at'     => @work_time.to_f,
        'queue'  => @queue,
        'class'  => @worker_name,
        'args'   => @args,
        'rq:ctr' => @contract.to_array,
        'rq:sdl' => nil
      }

      Sidekiq::Client.push(client_args)
    end
  end
end