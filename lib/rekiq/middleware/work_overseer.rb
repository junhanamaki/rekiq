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

        contract = Contract.from_array(msg['rq:ctr'])

        if worker.class.cancel_rekiq_worker?(*@contract.cancel_args)
          return logger.info "worker #{worker.name} was canceled"
        end

        if msg.key?('rq:sdl')
          msg.delete('rq:sdl')
        else
          return yield
        end

        scheduler = Rekiq::Scheduler.new(worker, queue, msg['args'], contract)

        unless contract.schedule_post_work?
          scheduler.schedule_next_work(Time.at(msg['at'].to_f))
          yield
        else
          begin
            yield
          ensure
            scheduler.schedule_next_work(Time.at(msg['at'].to_f))
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