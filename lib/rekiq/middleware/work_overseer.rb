require 'sidekiq'
require 'sidekiq/util'
require 'rekiq/job'
require 'rekiq/scheduler'

module Rekiq
  module Middleware
    class WorkOverseer
      include ::Sidekiq::Util

      def call(worker, msg, queue)
        return yield unless msg.key?('rq:job')

        setup_vars(worker, msg, queue)

        if cancel_worker?
          return logger.info 'worker canceled by rekiq cancel method'
        end

        return yield unless msg.key?('rq:schdlr')

        msg.delete('rq:schdlr')

        begin
          schedule_next_work unless @job.schedule_post_work?
          yield
        ensure
          schedule_next_work if @job.schedule_post_work?
        end
      end

    protected

      def setup_vars(worker, msg, queue)
        @cancel_method = worker.rekiq_cancel_method
        @cancel_args   = msg['rq:ca']
        @worker      = worker
        @worker_name = worker.class.name
        @queue       = queue
        @args        = msg['args']
        @job         = Job.from_array(msg['rq:job'])
        @addon       = msg['rq:addon']
        @scheduled_work_time = Time.at(msg['rq:at'].to_f)
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
            .new(@worker_name, @queue, @args, @job, @addon, @cancel_args)
            .schedule_from_work_time(@scheduled_work_time)

        unless jid.nil?
          logger.info "recurring work for #{@worker_name} scheduled for " \
                      "#{work_time} with jid #{jid}"
        else
          logger.info 'recurrence terminated, job terminated'
        end
      end
    end
  end
end