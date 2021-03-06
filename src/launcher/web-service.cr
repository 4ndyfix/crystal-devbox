require "kemal"
require "./cmd-line"
require "ansi2html"

module DevboxLauncher
  class WebService
    ::Log.setup :debug
    ::Log::StaticFormatter.colorized = true
    Log = ::Log.for self.name
    BROWSER = "/usr/bin/firefox"
    PORT = 12345

    def self.up
      Kemal.config.port = PORT
      spawn try_open_ui(BROWSER, PORT)
      Kemal.run
    rescue exc : Socket::BindError # Address already in use 
      Log.warn { "Launcher service is already running! - Try to open web UI anyway ..." }
      sleep 2.0 # sec
    end

    get "/" do |env|
      env.redirect "/welcome"
    end

    get "/welcome" do |env|
      text_result = "<pre><br>Logs will be displayed like DevboxLauncher's CLI terminal output .<br><br></pre>"
      render "public/views/launch.ecr"
    end

    get "/launch" do |env|
      get_params = env.params.query
      tool = get_params["tool"]
      args = ["--#{tool}"]
      env = {"MODE" => "CLI"}
      #
      launcher = Process.executable_path.as(String)
      output, error = IO::Memory.new, IO::Memory.new
      status = Process.run(launcher, args: args, env: env, output: output, error: error)
      stdout, stderr = output.to_s, error.to_s
      #
      ansi2html = Ansi2Html.new
      text_result = String.build do |sb|
        sb << ansi2html.convert stdout unless stdout.empty?
        sb << ansi2html.convert stderr unless stderr.empty?
      end
      text_result = "no output" unless text_result
      render "public/views/launch.ecr"
    end

    error 404 do |env|
      render "public/views/not_found.ecr"
    end

    def self.try_open_ui(browser : String, port : Int32)
      Log.info { "Try to connect Crystal devbox-launcher socket ..." }
      if CmdLine.with_retries(5) { CmdLine.server_socket_connectable? "localhost", port }
        Log.info { "Crystal devbox-launcher socket is connectable." }
      else
        Log.error { "Sorry, Crystal devbox-launcher socket isn't connectable!" }
      end
      #
      Log.info { "Check Crystal devbox-launcher service ..." }
      if CmdLine.with_retries(5) { CmdLine.service_available? "localhost", port }
        Log.info { "Crystal devbox-launcher service is available." }
      else
        Log.error { "Sorry, Crystal devbox-launcher service is not available!" }
      end
      CmdLine.open_in_browser browser, "http://localhost:#{port}"
    end
  end
end
