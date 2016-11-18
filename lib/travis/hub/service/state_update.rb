module Travis
  module Hub
    module Service
      class StateUpdate < Struct.new(:data)
        class Counter < Struct.new(:job_id, :redis)
          TTL = 3600 * 12

          def count
            @count ||= redis.get(key).to_i
          end

          def increment
            count = redis.incr(key)
            redis.expire(key, TTL)
            count
          end

          private

            def key
              "job:state_update_count:#{job_id}"
            end
        end

        include Helper::Context

        MSGS = {
          missing:   'Received state update with no count for job id=%p, last known count: %p.',
          ordered:   'Received state update %p for job id=%p, last known count: %p',
          unordered: 'Received state update %p for job id=%p, last known count: %p. %s',
          skip:      'Skipping the message.'
        }

        def apply?
          return missing unless given?
          apply = ordered? ? ordered : unordered
          return true unless ENV['UPDATE_COUNT']
          apply
        end

        private

          def given?
            !count.nil?
          end

          def missing
            warn :missing, job_id, counter.count
            true
          end

          def ordered
            info :ordered, count, job_id, counter.count
            true
          end

          def unordered
            warn :unordered, count, job_id, counter.count, ENV['UPDATE_COUNT'] ? MSGS[:skip] : ''
            false
          end

          def ordered?
            count >= counter.count
          end

          def counter
            @counter ||= Counter.new(job_id, redis)
          end

          def job_id
            data[:id]
          end

          def count
            meta[:state_update_count]
          end

          def meta
            data[:meta] || {}
          end
      end
    end
  end
end
