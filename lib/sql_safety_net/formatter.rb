require 'rack'

module SqlSafetyNet
  # Formatter to output information from a query analysis in various formats.
  class Formatter
    attr_reader :analysis
    
    def initialize(analysis)
      @analysis = analysis
    end
    
    def to_html
      uncached_analysis = QueryAnalysis.new
      cached_analysis = QueryAnalysis.new
      analysis.queries.each{ |query| query.cached? ? cached_analysis << query : uncached_analysis << query }
      
      ok_color = "#060"
      warn_color = "#900"
      cache_warn_color = "#A80"
      theme_color = ok_color
      theme_color = cache_warn_color if uncached_analysis.flagged?
      theme_color = warn_color if analysis.flagged?
      close_js = "document.getElementById('_sql_safety_net_').style.display = 'none'"
      toggle_queries_js = "document.getElementById('_sql_safety_net_queries_').style.display = (document.getElementById('_sql_safety_net_queries_').style.display == 'block' ? 'none' : 'block')"
      
      tag(:div, :id => "_sql_safety_net_", :style => div_style(SqlSafetyNet.config.style)) do
        tag(:div, :style => "padding:4px; background-color:#{theme_color}; font-weight:bold; color:#FFF;") do
          tag(:div) do
            tag(:a, :href => "javascript:void(#{close_js})", :style => "float:right; display:block; text-decoration:none") do
              tag(:span, "&times;", :style => "color:#FFF; text-decoration:none; font-weight:bold;")
            end
            tag(:a, :href => "javascript:void(#{toggle_queries_js})", :style => "text-decoration:none;") do
              tag(:span, "#{analysis.flagged? ? 'SQL WARNING' : 'SQL INFO'} &raquo;", :style => "color:#FFF; text-decoration:none; font-weight:bold;")
            end
          end
          tag(:div, summary, :style => "font-weight:normal;")
        end
        
        tag(:div, :id => "_sql_safety_net_queries_", :style => "display:none; border:1px solid #{theme_color}; background-color:#FFF; color:#000; overflow:auto; max-height:500px;") do
          tag(:div, :style => "padding-left:4px; padding-right:4px;") do
            if cached_analysis.total_queries > 0
              tag(:div, :style => "margin-top:5px; margin-bottom:5px;") do
                tag(:div, "Uncached", :style => "font-weight:bold;")
                tag(:div, Formatter.new(uncached_analysis).summary)
              end
              
              tag(:div, :style => "margin-top:5px; margin-bottom:5px; color:#066;") do
                tag(:div, "Cached", :style => "font-weight:bold;")
                tag(:div, Formatter.new(cached_analysis).summary)
              end
            end
          
            warning_style = "color:#{warn_color}; margin-top:5px; margin-bottom:5px;"
            tag(:div, "WARNING: #{analysis.total_queries} queries", :style => warning_style) if analysis.too_many_queries?
            tag(:div, "WARNING: #{analysis.rows} rows returned", :style => warning_style) if analysis.too_many_rows?
            tag(:div, "WARNING: #{sprintf('%0.1f', analysis.result_size / 1024.0)}K returned", :style => warning_style) if analysis.results_too_big?
            tag(:div, "WARNING: queries took #{(analysis.elapsed_time * 1000).round} ms", :style => warning_style) if analysis.too_much_time?
            tag(:div, "WARNING: alerts on #{analysis.alerted_queries} queries", :style => warning_style) if analysis.alerts?
          end
          
          analysis.queries.each do |query|
            color = ok_color
            if query.alerts?
              color = (query.cached? ? cache_warn_color : warn_color)
            end
            tag(:div, :style => "color:#{color}; border-top:1px solid #CCC; padding:8px 4px;#{' background-color:#DEE;' if query.cached?}") do
              tag(:div, "CACHED", :style => "color:#066;") if query.cached?
              query_info = "#{query.rows} row#{'s' if query.rows != 1} returned (#{sprintf('%0.1f', query.result_size / 1024.0)}K) in #{(query.elapsed_time * 1000).round} ms"
              tag(:div, query_info, :style => "margin-bottom:5px;")
              if query.alerts?
                tag(:div, :style => "margin-bottom:5px;") do
                  query.alerts.each do |alert|
                    tag(:div, alert, :style => "margin-bottom:2px;")
                  end
                end
              end
              tag(:div, query.sql, :style => "color:#666")
            end
          end
        end
      end
    end
    
    def to_s
      uncached_analysis = QueryAnalysis.new
      cached_analysis = QueryAnalysis.new
      analysis.queries.each{ |query| query.cached? ? cached_analysis << query : uncached_analysis << query }
      lines = []
      lines << "#{analysis.flagged? ? 'SQL WARNING' : 'SQL INFO'}: #{summary}"
      if cached_analysis.total_queries > 0
        lines << "UNCACHED: #{Formatter.new(uncached_analysis).summary}"
        lines << "CACHED: #{Formatter.new(cached_analysis).summary}"
      end
      lines << "WARNING: #{analysis.total_queries} queries" if analysis.too_many_queries?
      lines << "WARNING: #{analysis.rows} rows returned" if analysis.too_many_rows?
      lines << "WARNING: #{analysis.result_size}K returned" if analysis.results_too_big?
      lines << "WARNING: queries took #{(analysis.elapsed_time * 1000).round} ms" if analysis.too_much_time?
      lines << "WARNING: alerts on #{analysis.alerted_queries} queries" if analysis.alerts?
      analysis.queries.each do |query|
        lines << "-----------------"
        lines << "CACHED" if query.cached?
        lines << "#{query.rows} row#{'s' if query.rows != 1} returned (#{sprintf('%0.1f', query.result_size / 1024.0)}K) in #{(query.elapsed_time * 1000).round} ms"
        lines.concat(query.alerts)
        lines << "#{query.sql}"
      end
      lines.join("\n")
    end
    
    def summary
      queries = analysis.total_queries
      rows = analysis.rows
      kilobytes = analysis.result_size / 1024.0
      "#{queries} #{queries == 1 ? 'query' : 'queries'}, #{analysis.rows} row#{rows == 1 ? '' : 's'}, #{sprintf("%0.1f", kilobytes)}K, #{(analysis.elapsed_time * 1000).round}ms"
    end
    
    # Turn a hash of styles into a proper CSS style attribute. The style will use specified defaults
    # to make the div appear in the top, right corner of the page at 160px wide.
    def div_style(style)
      default_style = {
        "font-family" => "sans-serif",
        "font-size" => "10px",
        "font-weight" => "normal",
        "position" => "fixed",
        "z-index" => "999999",
        "text-align" => "left",
        "line-height" => "100%",
        "width" => "200px"
      }
      
      style = default_style.merge(style)
      style.delete_if{|key, value| value.blank? }
      
      # Ensure a default positioning
      if %w(fixed static absolute).include?(style["position"])
        style["top"] = "5px" if style["top"].blank? && style["bottom"].blank?
        style["right"] = "5px" if style["right"].blank? && style["left"].blank?
      end
      
      css_style = ""
      style.each do |name, value|
        css_style << "#{name}:#{value};"
      end
      css_style
    end
    
    private
    
    # Helper to generate an HTML tag.
    def tag(name, *args)
      attributes = args.extract_options!
      body = args.first
      
      @buffer ||= []
      output = ""
      @buffer.push(output)
      output << "<#{name}"
      if attributes
        attributes.each do |key, value|
          output << " #{key}=\"#{Rack::Utils.escape_html(value)}\""
        end
      end
      if block_given? || body
        output << ">"
        if block_given?
          yield
        else
          output << body if body
        end
        output << "</#{name}>"
      else
        output << "/>"
      end
      @buffer.pop
      @buffer.last << output unless @buffer.empty?
      output
    end
  end
end
