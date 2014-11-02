module Rekiq
  module Middleware
    class Utils
      def call(worker, msg, queue)
        if msg.key?('rq:at')
          worker.scheduled_work_time = Time.at(msg['rq:at'].to_f).utc
        end

        yield
      end
    end
  end
end