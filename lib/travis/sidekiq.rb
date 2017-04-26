require 'sidekiq/pro/expiry'

module Travis
  module Sidekiq
    extend self

    def hub(*args)
      client.push(
        'queue' => 'hub',
        'class' => 'Travis::Hub::Sidekiq::Worker',
        'args'  => args
      )
    end

    def scheduler(*args)
      client.push(
        'queue' => ENV['SCHEDULER_SIDEKIQ_QUEUE'] || 'scheduler',
        'class' => 'Travis::Scheduler::Worker',
        'args'  => [:event, *args]
      )
    end

    def tasks(name, *args)
      client.push(
        'queue'   => queue.to_s,
        'class'   => 'Travis::Async::Sidekiq::Worker',
        'args'    => [nil, "Travis::Addons::#{name}::Task", 'perform', *args]
      )
    end

    def live(*args)
      client.push(
        'queue'   => 'pusher-live',
        'class'   => 'Travis::Async::Sidekiq::Worker',
        'args'    => [nil, "Travis::Addons::Pusher::Task", 'perform', *args]
      )
    end

    private

      def client
        ::Sidekiq::Client
      end
  end
end
