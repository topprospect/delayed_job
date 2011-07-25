# Re-definitions are appended to existing tasks
task :environment
task :merb_env

namespace :jobs do
  desc "Clear the delayed_job queue."
  task :clear => [:merb_env, :environment] do
    Delayed::Job.delete_all
  end

  desc "Start a delayed_job worker with an optional log name"
  task :work, [:logname] => [:merb_env, :environment] do |_, args|

    Delayed::Worker.new(:min_priority => ENV['MIN_PRIORITY'],
                        :max_priority => ENV['MAX_PRIORITY'],
                        :queue => ENV['QUEUE'],
                        :logname => args.logname
    ).start
  end
end
