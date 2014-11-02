module Rekiq
  module Middleware
    class Utils
      def call(worker, msg, queue)
        if msg.key?('rq:ctr')
          worker.scheduled_work_time = Time.at(msg['at'].to_f).utc
        end

        yield
      end
    end
  end
end