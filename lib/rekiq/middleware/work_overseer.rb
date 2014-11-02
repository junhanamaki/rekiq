require 'sidekiq'
require 'sidekiq/util'
require 'rekiq/contract'
require 'rekiq/scheduler'

module Rekiq
  module Middleware
    class WorkOverseer
      include ::Sidekiq::Util

      def call(worker, msg, queue)
        return yield unless msg.key?('rq:ctr')

        @worker      = worker
        @worker_name = worker.class.name
        @msg         = msg
        @queue       = queue
        @contract    = Contract.from_hash(msg['rq:ctr'])

        if cancel_worker?
          return logger.info "worker #{@worker_name} was canceled"
        end

        if msg.key?('rq:sdl')
          msg.delete('rq:sdl')
        else
          return yield
        end

        begin
          reschedule unless @contract.schedule_post_work?
          yield
        ensure
          reschedule if @contract.schedule_post_work?
        end
      end

    protected

      def cancel_worker?
        @worker.cancel_rekiq_worker?(*@contract.cancel_args)
      end

      def reschedule
        jid, work_time =
          Rekiq::Scheduler
            .new(@worker_name, @queue, @msg['args'], @contract)
            .schedule_next_work(Time.at(@msg['rq:at'].to_f))

        unless jid.nil?
          logger.info "worker #{@worker_name} scheduled for " \
                      "#{work_time} with jid #{jid}"
        else
          logger.info 'recurrence terminated, worker terminated'
        end
      end
    end
  end
end