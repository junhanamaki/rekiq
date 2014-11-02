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

        if worker.cancel_rekiq_worker?(*contract.cancel_args)
          return logger.info "worker #{worker.class.name} was canceled"
        end

        if msg.key?('rq:sdl')
          msg.delete('rq:sdl')
        else
          return yield
        end

        worker_name        = worker.class.name
        binding.pry
        previous_work_time = Time.at(msg['rq:at'].to_f)
        binding.pry
        scheduler = Rekiq::Scheduler.new(worker_name, queue, msg['args'], contract)

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
          logger.info "worker #{worker_name} scheduled for " \
                      "#{work_time} with jid #{jid}"
        else
          logger.info 'recurrence terminated, worker terminated'
        end
      end
    end
  end
end