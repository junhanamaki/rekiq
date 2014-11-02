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

        scheduler =
          Rekiq::Scheduler
            .new(worker, queue, msg['args'], Contract.from_array(msg['rq:ctr']))

        if scheduler.cancel_worker?
          return logger.info "worker #{worker.name} was canceled"
        end

        return yield unless msg.key?('rq:sdl')

        msg.delete('rq:sdl')

        unless scheduler.schedule_post_work?
          scheduler.schedule(Time.at(msg['at'].to_f))
          yield
        else
          begin
            yield
          ensure
            scheduler.schedule(Time.at(msg['at'].to_f))
          end
        end

        unless jid.nil?
          logger.info "worker #{worker.name} scheduled for #{work_time} " \
                      "with job id #{jid}"
        else
          logger.info 'recurrence terminated, worker terminated'
        end
      end
    end
  end
end