# encoding: utf-8

class PassthroughController < ActionController::Base
  @@forwarder = Forwarder.new("pizza.de")

  def pass
    rewrite
  end

  after_filter :add_missing_content_type, only: :pass_cached
  caches_action :pass_cached, expires_in: 24.hours
  def pass_cached
    return rewrite
  end

  private
  def add_missing_content_type
    headers['Content-Type'] ||= Mime::Type.lookup_by_extension(params['ending']).to_s
  end

  def rewrite
    env['PATH_INFO'].sub!(%r{^/pizzade}, "")
    env['PATH_INFO'] = "" if env['PATH_INFO'].empty?
    ret = @@forwarder.call(env)
    inject!(ret)
    fix_urls!(ret)

    send_data ret[2].first, type: ret[1]["content-type"].first, disposition: 'inline', status: ret[0]
  end


  def inject!(ret)
    # heuristic: assume if the last part contains a dot, it’s not a
    # HTML resource
    last = env['PATH_INFO'].split("/").last
    return if last && last.include?(".")

    b = ret[2].first

    b.sub!("<head>", "<head>\n#{get_view(:head_top)}")
    b.sub!("<body>", "<body>\n#{get_view(:body_top)}")

    b.sub!("</head>", "</head>\n#{get_view(:head_bottom)}")
    b.sub!("</body>", "</body>\n#{get_view(:body_bottom)}")
  end

  def fix_urls!(ret)
    ret[2].first.gsub!("http://pizza.de", "")
    ret[2].first.gsub!("https://pizza.de", "")
  end

  def get_view(where)
    render_to_string partial: "passthrough/inject_#{where}.html.erb", locals: { environment: env }
  end
end