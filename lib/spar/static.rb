require 'rack/showexceptions'
require 'rack/mime'

module Spar

  class Static

    def call(env)
      path = env["PATH_INFO"]

      # Try getting the file form the public directory - this overrides everything
      public_path = "#{Spar.root.join('public')}/#{path}"
      if File.exists?(public_path)
        return send_static(public_path, env)
      end

      # Try getting the file form the static directory
      static_path = "#{Spar.root.join('static')}/#{path}"
      if File.exists?(static_path)
        return send_static(static_path, env)
      end

      # Try getting the file form the local spar gems assets
      spar_file = "#{File.dirname(__FILE__)}/assets/#{path.gsub('__spar__/','')}"
      if File.exists?(spar_file)
        return send_static(spar_file, env) 
      end

      # Return a 404 but let it pass on with the X-Cascade header
      [ 404, { "Content-Type" => "text/plain", "Content-Length" => "9", "X-Cascade" => "pass" }, [ "Not found" ] ]
    end

    def send_static(path, env)
      last_modified = File.mtime(path).httpdate
      return [304, {}, []] if env['HTTP_IF_MODIFIED_SINCE'] == last_modified
      [ 200, 
        {
          "Last-Modified" => last_modified,
          "Content-Type" => Rack::Mime.mime_type(File.extname(path), 'text/plain')
        },
        File.new(path)
      ]
    end

  end
end