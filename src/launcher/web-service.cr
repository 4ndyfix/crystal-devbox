require "kemal"
require "./cmd-line"
require "ansi2html"

module DevboxLauncher
  class WebService
    def self.up
      Kemal.run
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
  end
end
