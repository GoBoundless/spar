require 'rack/showexceptions'
require 'rack/mime'

module Spar
  # Sinatra::ShowExceptions catches all exceptions raised from the app it
  # wraps. It shows a useful backtrace with the sourcefile and clickable
  # context, the whole Rack environment and the request data.
  #
  # Be careful when you use this on public-facing sites as it could reveal
  # information helpful to attackers.
  class PublicAssets < Rack::ShowExceptions

    def initialize
      @template = ERB.new(TEMPLATE)
    end

    def call(env)
      path = env["PATH_INFO"]

      public_path = "#{Spar.root.join('public')}/#{path}"
      if File.exists?(public_path)
        [200, { "Content-Type" => Rack::Mime.mime_type(File.extname(public_path), 'text/plain')}, File.new(public_path)]
      else
        spar_file = "#{File.dirname(__FILE__)}/assets/#{path.gsub('__spar__/','')}"
        if File.exists?(spar_file)
          [200, { "Content-Type" => Rack::Mime.mime_type(File.extname(spar_file), 'text/plain')}, File.new(spar_file)]
        else
          body = [@template.result(binding)]

          [404,
           {"Content-Type" => "text/html",
            "Content-Length" => Rack::Utils.bytesize(body.join).to_s},
           body]
        end
      end
    end

TEMPLATE = <<-HTML # :nodoc:
<!DOCTYPE html>
<html>
<head>
  <meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
  <title>Not Found: <%=h path %></title>

<style type="text/css" media="screen">
  html                {min-height: 100%; height: 100%;}
  *                   {margin: 0; padding: 0; border: 0; outline: 0;}
  body                {background: #EEEEEE; margin: 0; padding: 0;
                       font-family: 'Lucida Grande', 'Lucida Sans Unicode',
                       'Garuda';
                       min-height: 100%; height: 100%;}
  code                {font-family: 'Lucida Console', monospace;
                       font-size: 12px;}
  li                  {height: 18px;}
  ul                  {list-style: none; margin: 0; padding: 0;}
  ol:hover            {cursor: pointer;}
  ol li               {white-space: pre;}
  #explanation        {font-size: 12px; color: #666666;
                       margin: 20px 0 0 100px;}
/* WRAP */
  #wrap               {width: 1000px; background: #FFFFFF; margin: 0 auto; min-height: 100%; height: 100%;
                       padding: 110px 50px 20px;
                       text-align: center;
                       border-left: 1px solid #DDDDDD;
                       border-right: 1px solid #DDDDDD;}
  h1                  {margin: 20px 0 0; font-size: 36px; color: #BE292B;}
  h2                  {margin: 0; font-size: 22px; color: #333333;}
</style>
</head>
<body>
  <div id="wrap">
    <img src="<%= env['SCRIPT_NAME'] %>/__spar__/404.jpg" alt="application error" height="223" width="191" />
    <h1><strong>Spar couldn't find <strong><%=h path %></strong></h1>
    <h2>Error 404</h2>
  </div> <!-- /WRAP -->
  </body>
</html>
HTML
  end
end