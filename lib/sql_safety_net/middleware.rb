require 'rack'

module SqlSafetyNet
  # Rack middleware for analyzing queries on a request.
  #
  # The X-SqlSafetyNet header will be set with summary info about the queries.
  #
  # If the request responds with HTML and the request queries are flagged or if the +always_show+
  # option is set, debugging info will be injected into the page.
  class Middleware
    HTML_CONTENT_TYPE = /text\/(x?)html/i.freeze
    
    def initialize(app)
      @app = app
    end
    
    def call(env)
      QueryAnalysis.capture do |analysis|
        response = @app.call(env)
        unless analysis.queries.empty?
          formatter = Formatter.new(analysis)
          Rails.logger.debug(formatter.to_s) if ActiveRecord::Base.logger
          request = Rack::Request.new(env)
          wrapped_response = Rack::Response.new(response[2], response[0], response[1])
          wrapped_response["X-SqlSafetyNet"] = formatter.summary
        
          if SqlSafetyNet.config.always_show || analysis.flagged?
            unless request.xhr? || analysis.queries.empty?
              content_type = wrapped_response.content_type
              if content_type && content_type.match(HTML_CONTENT_TYPE) && !wrapped_response.redirection?
                wrapped_response.write(formatter.to_html)
              end
            end
          end
          response = wrapped_response.finish
        end
        response
      end
    end
  end
end
