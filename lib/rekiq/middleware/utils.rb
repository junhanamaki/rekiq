module Rekiq
  module Middleware
    class Utils
      def call(worker, msg, queue)
        if worker.respond_to?(:scheduled_work_time) and
           msg.key?('rq:at')
          worker.scheduled_work_time = Time.at(msg['rq:at']).utc
        end

        yield
      end
    end
  end
end