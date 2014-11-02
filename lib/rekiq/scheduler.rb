module Rekiq
  class Scheduler
    def initialize(worker, queue, args, contract)
      @worker   = worker
      @queue    = queue
      @args     = args
      @contract = contract
    end

    def schedule_worker(previous_work_time = nil)
      from = previous_work_time || Time.now
      @work_time = next_work_time(from)

      @work_time.nil? ? nil : [push_to_redis, @work_time]
    end

    def cancel_worker?
      @worker.class.cancel_rekiq_worker?(*@contract.cancel_args)
    end

  protected

    def push_to_redis
      client_args = {
        'at'     => @work_time.to_f,
        'queue'  => @queue,
        'class'  => @worker.name,
        'args'   => @args,
        'rq:ctr' => @contract.to_hash,
        'rq:sdl' => nil
      }

      Sidekiq::Client.push(client_args)
    end
  end
end