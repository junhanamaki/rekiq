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

        contract = Contract.from_hash(msg['rq:ctr'])

        if worker.class.cancel_rekiq_worker?(*contract.cancel_args)
          return logger.info "worker #{worker.class.name} was canceled"
        end

        if msg.key?('rq:sdl')
          msg.delete('rq:sdl')
        else
          return yield
        end

        scheduler = Rekiq::Scheduler.new(worker, queue, msg['args'], contract)
        previous_work_time = Time.at(msg['at'].to_f)

        unless contract.schedule_post_work?
          jid, work_time = scheduler.schedule_next_work(previous_work_time)
          yield
        else
          begin
            yield
          ensure
            jid, work_time = scheduler.schedule_next_work(previous_work_time)
          end
        end

        unless jid.nil?
          logger.info "worker #{worker.class.name} scheduled for " \
                      "#{work_time} with jid #{jid}"
        else
          logger.info 'recurrence terminated, worker terminated'
        end
      end
    end
  end
end