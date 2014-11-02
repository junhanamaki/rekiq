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

        setup_vars(worker, msg, queue)

        if cancel_worker?
          return logger.info 'worker canceled by rekiq cancel method'
        end

        return yield unless msg.key?('rq:sdl')

        msg.delete('rq:sdl')

        begin
          schedule_next_work unless @contract.schedule_post_work?
          yield
        ensure
          schedule_next_work if @contract.schedule_post_work?
        end
      end

    protected

      def setup_vars(worker, msg, queue)
        @contract      = Contract.from_array(msg['rq:ctr'])
        @cancel_method = worker.rekiq_cancel_method
        @cancel_args   = @contract.cancel_args
        @worker        = worker
        @worker_name   = worker.class.name
        @queue         = queue
        @args          = msg['args']
        @scheduled_work_time = Time.at(msg['at'].to_f)
      end

      def cancel_worker?
        !@cancel_method.nil? and @worker.send(@cancel_method, *@cancel_args)
      rescue StandardError => s
        raise CancelMethodInvocationError,
              "error while invoking rekiq_cancel_method with message " \
              "#{s.message}",
              s.backtrace
      end

      def schedule_next_work
        jid, work_time =
          Rekiq::Scheduler
            .new(@worker_name, @queue, @args, @contract)
            .schedule_from_work_time(@scheduled_work_time)

        unless jid.nil?
          logger.info "worker #{@worker_name} scheduled for #{work_time} " \
                      "with jid #{jid}"
        else
          logger.info 'recurrence terminated, worker terminated'
        end
      end
    end
  end
end