module Rekiq
  module Middleware
    class Utils
      def call(worker, msg, queue)
        if worker.respond_to?(:scheduled_work_time) and
           msg.key?('scheduled_work_time')
          worker.scheduled_work_time = Time.at(msg['scheduled_work_time']).utc
        end

        yield
      end
    end
  end
end