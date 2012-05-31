require 'rack'

module SqlSafetyNet
  # This Rack handler must be added to the middleware stack in order for query analysis to be output.
  # If the configuration option for debug is set to true, it will add response headers indicating information
  # about the queries executed in the course of the request.
  class RackHandler
    
    X_SQL_SAFETY_NET_HEADER = "X-SqlSafetyNet".freeze
    HTML_CONTENT_TYPE_PATTERN = /text\/(x?)html/i
    XML_CONTENT_TYPE_PATTERN = /application\/xml/i
    
    def initialize(app, logger = Rails.logger)
      @app = app
      @logger = logger
    end
    
    def call(env)
      response = nil
      analysis = QueryAnalysis.analyze do
        response = @app.call(env)
      end
      
      if @logger && (analysis.too_many_selects? || analysis.too_many_rows?)
        request = Rack::Request.new(env)
        @logger.warn("Excess database usage: request generated #{analysis.selects} queries and returned #{analysis.rows} rows [#{request.request_method} #{request.url}]")
      end
      
      # Add a response header that contains a summary of the debug info
      if SqlSafetyNet.config.header? || SqlSafetyNet.config.debug?
        headers = response[1]
        headers[X_SQL_SAFETY_NET_HEADER] = "selects=#{analysis.selects}; rows=#{analysis.rows}; elapsed_time=#{(analysis.elapsed_time * 1000).round}; flagged_queries=#{analysis.flagged_queries.size}" if headers
      end
      
      if SqlSafetyNet.config.debug?
        wrapped_response = Rack::Response.new(response[2], response[0], response[1])
        if analysis.flagged? || SqlSafetyNet.config.always_show?
          request = Rack::Request.new(env)
          # Ignore Ajax calls
          unless request.xhr?
            # Only if content type is text/html
            type = wrapped_response.content_type
            if type.nil? || type.to_s.match(HTML_CONTENT_TYPE_PATTERN)
              wrapped_response.write(flagged_sql_html(analysis))
            elsif type.to_s.match(XML_CONTENT_TYPE_PATTERN)
              wrapped_response.write(xml_comment(flagged_sql_text(analysis)))
            end
          end
        end
        response = wrapped_response.finish
      end
      
      response
    end

    def flagged_sql_html(analysis)
      flagged_html = ''
      cached_selects = 0
      cached_rows = 0
      cached_elapsed_time = 0.0
      
      if analysis.flagged_queries?
        flagged_html << '<div style="color:#C00;">'
        flagged_html << "<div style=\"font-weight:bold; margin-bottom:10px;\">#{analysis.flagged_queries.size == 1 ? 'This query has' : "These #{analysis.flagged_queries.size} queries have"} flagged query plans:</div>"
        analysis.flagged_queries.each do |query|
          if query[:cached]
            cached_selects += 1
            cached_rows += query[:rows]
            cached_elapsed_time += query[:elapsed_time]
          end
          flagged_html << '<div style="margin-bottom:10px;">'
          flagged_html << "<div style=\"font-weight:bold; margin-bottom: 5px;\">#{query[:rows]} rows returned, #{(query[:elapsed_time] * 1000).round} ms#{ " <span style='color:teal;'>(CACHED)</span>" if query[:cached]}</div>"
          flagged_html << "<div style=\"font-weight:bold; margin-bottom: 5px;\">#{query[:flags].join(', ')}</div>"
          flagged_html << "<div style=\"margin-bottom: 5px;\">#{Rack::Utils.escape_html(query[:sql])}</div>"
          flagged_html << "<div style=\"margin-bottom: 5px;\">Query Plan: #{Rack::Utils.escape_html(query[:query_plan].inspect)}</div>" if query[:query_plan]
          flagged_html << '</div>'
        end
        flagged_html << '</div>'
      end
      
      if analysis.too_many_selects? || analysis.too_many_rows? || SqlSafetyNet.config.always_show?
        flagged_html << "<div style=\"font-weight:bold; margin-bottom:10px;\">#{analysis.non_flagged_queries.size == 1 ? 'This query' : "These #{analysis.non_flagged_queries.size} queries"} did not have flagged query plans:</div>"
        analysis.non_flagged_queries.each do |query|
          if query[:cached]
            cached_selects += 1
            cached_rows += query[:rows]
            cached_elapsed_time += query[:elapsed_time]
          end
          flagged_html << '<div style="margin-bottom:10px;">'
          flagged_html << "<div style=\"font-weight:bold; margin-bottom: 5px;\">#{query[:rows]} rows returned, #{(query[:elapsed_time] * 1000).round} ms#{ " <span style='color:teal;'>(CACHED)</span>" if query[:cached]}</div>"
          flagged_html << "<div style=\"margin-bottom: 5px;\">#{Rack::Utils.escape_html(query[:sql])}</div>"
          flagged_html << '</div>'
        end
      end

      color_scheme = '#060'
      if analysis.flagged_queries?
        color_scheme = '#C00' 
      elsif analysis.flagged?
        color_scheme = '#C60'
      end
      label = (analysis.flagged?) ? 'SQL WARNING' : 'SQL INFO'
      
      cache_html = nil
      if cached_selects > 0
        cache_html = <<-EOS
          <div style="margin-bottom:10px; font-weight:bold;">
            Some of the queries will be cached.
            <div style="color:#C00;">
              Uncached: #{analysis.selects - cached_selects} selects, #{analysis.rows - cached_rows} rows, #{((analysis.elapsed_time - cached_elapsed_time) * 1000).round} ms
            </div> 
            <div style="color:teal;">
              Cached: #{cached_selects} selects, #{cached_rows} rows, #{(cached_elapsed_time * 1000).round} ms
            </div> 
          </div>
        EOS
      end
      
      <<-EOS
        <div id="sql_safety_net_warning" style="font-family:sans-serif; font-size:10px; position:fixed; z-index:999999999; text-align:left; #{SqlSafetyNet.config.position}">
          <div style="background-color:#{color_scheme}; color:#FFF; padding:4px; width:160px; float:right;">
            <a href="javascript:void(document.getElementById('sql_safety_net_warning').style.display = 'none')" style="text-decoration:none; float:right; display:block; font-size:9px;"><span style="color:#FFF; text-decoration:none; font-weight:bold;">&times;</span></a>
            <a href="javascript:void(document.getElementById('sql_safety_net_flagged_queries').style.display = (document.getElementById('sql_safety_net_flagged_queries').style.display == 'block' ? 'none' : 'block'))" style="text-decoration:none;">
              <span style="color:#FFF; text-decoration:none; font-weight:bold;">#{label} &raquo;</span>
            </a>
            <div>#{analysis.selects} selects, #{analysis.rows} rows, #{(analysis.elapsed_time * 1000).round} ms</div>
          </div>
          <div id="sql_safety_net_flagged_queries" style="clear:right; display:none; width:500px; padding:2px; border:1px solid #{color_scheme}; background-color:#FFF; color:#000; overflow:auto; max-height:500px;">
            <div style="margin-bottom:10px; font-weight:bold;">
              There are #{analysis.selects} queries on this page that return #{analysis.rows} rows and took #{(analysis.elapsed_time * 1000).round} ms to execute.
            </div>
            #{cache_html}
            #{flagged_html}
          </div>
        </div>
      EOS
    end

    def flagged_sql_text(analysis)
      flagged_text = ''
      cached_selects = 0
      cached_rows = 0
      cached_elapsed_time = 0.0
      
      if analysis.flagged_queries?
        flagged_text << "#{analysis.flagged_queries.size == 1 ? 'This query has' : "These #{analysis.flagged_queries.size} queries have"} flagged query plans:\n\n"
        analysis.flagged_queries.each do |query|
          if query[:cached]
            cached_selects += 1
            cached_rows += query[:rows]
            cached_elapsed_time += query[:elapsed_time]
          end
          flagged_text << "#{query[:rows]} rows returned, #{(query[:elapsed_time] * 1000).round} ms#{ " (CACHED)" if query[:cached]}\n"
          flagged_text << "#{query[:flags].join(', ')}\n\n"
          flagged_text << "#{query[:sql]}\n\n"
          flagged_text << "Query Plan: #{Rack::Utils.escape_html(query[:query_plan].inspect)}\n" if query[:query_plan]
          flagged_text << "\n"
        end
        flagged_text << "\n"
      end
      
      if analysis.too_many_selects? || analysis.too_many_rows? || SqlSafetyNet.config.always_show?
        flagged_text << "#{analysis.non_flagged_queries.size == 1 ? 'This query' : "These #{analysis.non_flagged_queries.size} queries"} did not have flagged query plans:\n\n"
        analysis.non_flagged_queries.each do |query|
          if query[:cached]
            cached_selects += 1
            cached_rows += query[:rows]
            cached_elapsed_time += query[:elapsed_time]
          end
          flagged_text << "#{query[:rows]} rows returned, #{(query[:elapsed_time] * 1000).round} ms#{ " (CACHED)" if query[:cached]}\n\n"
          flagged_text << "#{query[:sql]}\n\n"
          flagged_text << "\n"
        end
      end

      label = (analysis.flagged?) ? 'SQL WARNING' : 'SQL INFO'
      
      cache_text = ""
      if cached_selects > 0
        cache_text << "Some of the queries will be cached.\n\n"
        cache_text << "Uncached: #{analysis.selects - cached_selects} selects, #{analysis.rows - cached_rows} rows, #{((analysis.elapsed_time - cached_elapsed_time) * 1000).round} ms\n"
        cache_text << "Cached: #{cached_selects} selects, #{cached_rows} rows, #{(cached_elapsed_time * 1000).round} ms\n\n"
      end
      
      text = "SqlSafetyNet\n\n"
      text << "There are #{analysis.selects} queries on this page that return #{analysis.rows} rows and took #{(analysis.elapsed_time * 1000).round} ms to execute.\n\n"
      text << cache_text
      text << flagged_text
      text
    end
    
    def xml_comment(text)
      "<!-- #{text.gsub('-->', '\\-\\->')} -->"
    end
  end
end
