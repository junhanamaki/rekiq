require 'sidekiq'
require 'sidekiq/util'
require 'rekiq/configuration'
require 'rekiq/job'
require 'rekiq/scheduler'

module Rekiq
  module Middleware
    class WorkOverseer
      include ::Sidekiq::Util

      attr_accessor :worker_name, :queue, :args, :job, :add_on,
                    :scheduled_work_time

      def call(worker, msg, queue)
        return yield unless msg['mandragora:job']

        self.worker_name = worker.class.name
        self.queue       = queue
        self.args        = msg['args']
        self.job         = Job.from_hash(msg['mandragora:job'])
        self.add_on      = msg['add_on']

        if msg['retry_count'].nil?
          self.scheduled_work_time = Time.at(msg['scheduled_work_time'].to_f)
          reschedule_post_work = job.reschedule_post_work?

          if reschedule_post_work
            begin
              yield
            ensure
              reschedule
            end
          else
            reschedule
            yield
          end
        else
          yield
        end
      end

      def reschedule
        jid, work_time =
          Rekiq::Scheduler
            .new(worker_name, queue, args, job, add_on)
            .schedule_from_work_time(scheduled_work_time)

        unless jid.nil?
          logger.info "recurring work for #{worker_name} scheduled for " \
                      "#{work_time} with jid #{jid}"
        else
          logger.info 'recurrence terminated, job terminated'
        end
      end
    end
  end
end