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
  *                   {margin: 0; padding: 0; border: 0; outline: 0;}
  div.clear           {clear: both;}
  body                {background: #EEEEEE; margin: 0; padding: 0;
                       font-family: 'Lucida Grande', 'Lucida Sans Unicode',
                       'Garuda';}
  code                {font-family: 'Lucida Console', monospace;
                       font-size: 12px;}
  li                  {height: 18px;}
  ul                  {list-style: none; margin: 0; padding: 0;}
  ol:hover            {cursor: pointer;}
  ol li               {white-space: pre;}
  #explanation        {font-size: 12px; color: #666666;
                       margin: 20px 0 0 100px;}
/* WRAP */
  #wrap               {width: 1000px; background: #FFFFFF; margin: 0 auto;
                       padding: 30px 50px 20px 50px;
                       border-left: 1px solid #DDDDDD;
                       border-right: 1px solid #DDDDDD;}
/* HEADER */
  #header             {margin: 0 auto 25px auto;}
  #header img         {float: left;}
  #header #summary    {float: left; margin: 12px 0 0 20px; width:660px;
                       font-family: 'Lucida Grande', 'Lucida Sans Unicode';}
  h1                  {margin: 0; font-size: 36px; color: #981919;}
  h2                  {margin: 0; font-size: 22px; color: #333333;}
  #header ul          {margin: 0; font-size: 12px; color: #666666;}
  #header ul li strong{color: #444444;}
  #header ul li       {display: inline; padding: 0 10px;}
  #header ul li.first {padding-left: 0;}
  #header ul li.last  {border: 0; padding-right: 0;}
/* BODY */
  #backtrace,
  #get,
  #post,
  #cookies,
  #rack               {width: 980px; margin: 0 auto 10px auto;}
  p#nav               {float: right; font-size: 14px;}
/* BACKTRACE */
  a#expando           {float: left; padding-left: 5px; color: #666666;
                      font-size: 14px; text-decoration: none; cursor: pointer;}
  a#expando:hover     {text-decoration: underline;}
  h3                  {float: left; width: 100px; margin-bottom: 10px;
                       color: #981919; font-size: 14px; font-weight: bold;}
  #nav a              {color: #666666; text-decoration: none; padding: 0 5px;}
  #backtrace li.frame-info {background: #f7f7f7; padding-left: 10px;
                           font-size: 12px; color: #333333;}
  #backtrace ul       {list-style-position: outside; border: 1px solid #E9E9E9;
                       border-bottom: 0;}
  #backtrace ol       {width: 920px; margin-left: 50px;
                       font: 10px 'Lucida Console', monospace; color: #666666;}
  #backtrace ol li    {border: 0; border-left: 1px solid #E9E9E9;
                       padding: 2px 0;}
  #backtrace ol code  {font-size: 10px; color: #555555; padding-left: 5px;}
  #backtrace-ul li    {border-bottom: 1px solid #E9E9E9; height: auto;
                       padding: 3px 0;}
  #backtrace-ul .code {padding: 6px 0 4px 0;}
  #backtrace.condensed .system,
  #backtrace.condensed .framework {display:none;}
/* REQUEST DATA */
  p.no-data           {padding-top: 2px; font-size: 12px; color: #666666;}
  table.req           {width: 980px; text-align: left; font-size: 12px;
                       color: #666666; padding: 0; border-spacing: 0;
                       border: 1px solid #EEEEEE; border-bottom: 0;
                       border-left: 0;
                       clear:both}
  table.req tr th     {padding: 2px 10px; font-weight: bold;
                       background: #F7F7F7; border-bottom: 1px solid #EEEEEE;
                       border-left: 1px solid #EEEEEE;}
  table.req tr td     {padding: 2px 20px 2px 10px;
                       border-bottom: 1px solid #EEEEEE;
                       border-left: 1px solid #EEEEEE;}
/* HIDE PRE/POST CODE AT START */
  .pre-context,
  .post-context       {display: none;}

  table td.code       {width:750px}
  table td.code div   {width:750px;overflow:hidden}
</style>
</head>
<body>
  <div id="wrap">
    <div id="header">
      <img src="<%= env['SCRIPT_NAME'] %>/__spar__/404.jpg" alt="application error" height="223" width="191" />
      <div id="summary">
        <h1><strong>Spar couldn't find <strong><%=h path %>
          </strong></h1>
        <h2>Try something else!</h2>
      </div>
    </div>

  </div> <!-- /WRAP -->
  </body>
</html>
HTML
  end
end