# frozen_string_literal: true

# New logging library for sinatra that can ignore certain urls
class FilteredCommonLogger < Rack::CommonLogger
  def initialize(app, urls)
    super
    @app = app
    @logging_blacklist = urls
  end

  def call(env)
    if filter_log?(env)
      # default CommonLogger behaviour: log and move on
      super
    else
      # pass request to next component without logging
      @app.call(env)
    end
  end

  # return true if request should be logged
  def filter_log?(env)
    !@logging_blacklist.include?(env['PATH_INFO'])
  end
end
