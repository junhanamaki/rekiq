require 'sidekiq'
require 'sidekiq/util'
require 'rekiq/job'
require 'rekiq/scheduler'

module Rekiq
  module Middleware
    class WorkOverseer
      include ::Sidekiq::Util

      def call(worker, msg, queue)
        return yield unless msg['rq:job'] and msg['retry_count'].nil?

        setup_vars(worker, msg, queue)

        if !@canceller_name.nil? and
           worker.send(@canceller_name, *@canceller_args)
          return logger.info 'worker canceled by recurrence canceller'
        end

        begin
          reschedule unless @job.schedule_post_work?
          yield
        ensure
          reschedule if @job.schedule_post_work?
        end
      end

    protected

      def setup_vars(worker, msg, queue)
        @canceller_name = worker.recurrence_canceller_name
        @canceller_args = msg['rq:ca']
        @worker_name = worker.class.name
        @queue       = queue
        @args        = msg['args']
        @job         = Job.from_array(msg['rq:job'])
        @addon       = msg['rq:addon']
        @scheduled_work_time = Time.at(msg['rq:at'].to_f)
      end

      def reschedule
        jid, work_time =
          Rekiq::Scheduler
            .new(@worker_name, @queue, @args, @job, @addon, @canceller_args)
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