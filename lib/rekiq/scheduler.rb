module Rekiq
  class Scheduler
    def initialize(worker_name, queue, args, contract)
      @worker_name = worker_name
      @queue       = queue
      @args        = args
      @contract    = contract
    end

    def schedule_initial_work(from = Time.now)
      @work_time = @contract.initial_work_time(from)
      schedule_work
    end

    def schedule_next_work(previous_work_time)
      @work_time = @contract.next_work_time(previous_work_time)
      schedule_work
    end

  protected

    def schedule_work
      @work_time.nil? ? nil : [push_to_redis, @work_time]
    end

    def push_to_redis
      client_args = {
        'at'     => @work_time.to_f,
        'queue'  => @queue,
        'class'  => @worker_name,
        'args'   => @args,
        'rq:ctr' => @contract.to_hash,
        'rq:sdl' => nil,
        'rq:at'  => @work_time.to_f # this needs to be here because the key 'at' is removed by sidekiq
      }

      Sidekiq::Client.push(client_args)
    end
  end
end