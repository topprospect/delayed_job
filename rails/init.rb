require 'delayed_job'

config.after_initialize do
  Delayed::Worker.guess_backend
end

# rename the default Rails logger file, if requested
# TODO should we put it inside a class/module?
#
# http://stackoverflow.com/questions/3500200/getting-delayed-job-to-log
# https://gist.github.com/833828

def rename_default_rails_log_if_given(filename)
  return unless filename and not filename.empty?

  f = open filename, (File::WRONLY | File::APPEND | File::CREAT)
  f.sync = true
  RAILS_DEFAULT_LOGGER.auto_flushing = true
  # TODO shouldn't we first close whatever was there?
  RAILS_DEFAULT_LOGGER.instance_variable_set(:@log, f)
end