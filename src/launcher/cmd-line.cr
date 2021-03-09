require "log"
require "./log-patch"
require "http/client"
require "option_parser"
require "colorize"
require "file_utils"

module DevboxLauncher
  class CmdLine
    Log       = ::Log.for self.name
    @playground_port : String
    @browser : String
    STAR_LINE = "*" * 80

    def initialize
      @reference, @api, @playground, @vscode = false, false, false, false
      @show_config_only, @colorize = false, true
      opts = {} of Symbol => String
      #
      OptionParser.parse ARGV do |parser|
        parser.banner = "#{PROGRAM_NAME.upcase}\nUsage: #{PROGRAM_NAME}\n"
        parser.on("-r", "--reference", "Open Crystal book (language reference)") { @reference = true }
        parser.on("-a", "--api", "Show Crystal API documentation") { @api = true }
        parser.on("-p", "--playground", "Launch Crystal playground") { @playground = true }
        parser.on("--playground-port=PORT", "Crystal playground service port") { |val| opts[:playground_port] = val }
        parser.on("-c", "--vscode", "Start VSCode Editor") { @vscode = true }
        parser.on("-n", "--no-colorize", "No colorized console output") { @colorize = false }
        parser.on("-l LEVEL", "--log-level=LEVEL", "Logging level as string") { |val| opts[:log_level] = val }
        parser.on("-b BROWSER", "--browser=BROWSER", "Which browser to use") { |val| opts[:browser] = val }
        parser.on("-s", "--show-config-only", "Show config only (instance vars)") { @show_config_only = true }
        parser.on("-v", "--version", "Show Crystal version info") { |val| puts VERSION; exit 0 }
        parser.on("-h", "--help", "Show this help") { |val| puts parser; exit 0 }
        parser.invalid_option do |flag|
          Log.error { "#{flag} is not a valid option! Try --help." }
        end
      end
      @colorize && ::Log::StaticFormatter.colorized = true
      @playground_port = opts[:playground_port]? || ENV["PLAYGROUND_PORT"]? || "48080"
      @log_level = opts[:log_level]? || ENV["LOG_LEVEL"]? || "DEBUG"
      @browser = opts[:browser]? || ENV["BROWSER"]? || "/usr/bin/firefox"
      ::Log.setup ::Log::LEVEL[@log_level]
      @show_config_only && (pp self; true) && exit 0
      if @reference | @api | @playground | @vscode == false
        Log.warn { "Sorry, nothing to launch! Try --help." }
      end
    end

    def self.daemonize(prog : String, params : Array(String), working_dir = FileUtils.pwd) : Bool
      Log.debug { "Start new Process: prog=#{prog}, params=#{params}, working_dir=#{working_dir}" }
      cmd = "start-stop-daemon"
      args = ["--start", "--background", "--chdir", working_dir, "--exec", prog, "--"].concat params
      output, error = IO::Memory.new, IO::Memory.new
      status = Process.run cmd, args: args, output: output, error: error
      success, stdout, stderr = status.success?, output.to_s, error.to_s
      Log.debug { "Process success=#{success} stdout='#{stdout}', stderr='#{stderr}'" }
      success
    end

    def self.server_socket_connectable?(host : String, port : Int32) : Bool
      Socket.tcp(Socket::Family::INET).connect "localhost", port
      true
    rescue Socket::ConnectError
      false
    end

    def self.service_available?(host : String, port : Int32) : Bool
      response = HTTP::Client.new(host, port).get "/"
      case response.status
      when HTTP::Status::OK, HTTP::Status::FOUND then true
      else false
      end
    end

    def self.with_retries(max : Int32, &block : -> Bool) : Bool
      success = block.call
      unless success
        1.upto max do |num|
          sleep 1.0 # sec
          success = block.call
          if success
            Log.debug { "Success for code block after #{num} retries." }
            break
          end
        end
      else
        Log.debug { "Success for code block without any retries." }
      end
      success
    end

    def self.open_in_browser(browser : String, url : String)
      Log.info { "Try to start #{browser} browser ..." }
      success = daemonize browser, ["#{url}"]
      if success
        Log.info { "Started a new #{browser} process." }
      else
        Log.error { "Couldn't start a new #{browser} process!" }
      end
    end

    def launch_reference
      Log.info { "Try to start Crystal book process ..." }
      success = CmdLine.daemonize "/usr/bin/make", ["serve"], working_dir: "/opt/crystal-book"
      if success
        Log.info { "Started a new Crystal book process." }
      else
        Log.error { "Couldn't start a new Crystal book process!" }
      end
      #  
      Log.info { "Try to connect Crystal book socket ..." }
      if CmdLine.with_retries(30) { CmdLine.server_socket_connectable? "localhost", 8000 }
        Log.info { "Crystal book socket is connectable." }
      else
        Log.error { "Sorry, Crystal book socket isn't connectable!" }
      end
      #
      Log.info { "Check Crystal book service ..." }
      if CmdLine.with_retries(3) { CmdLine.service_available? "localhost", 8000 }
        Log.info { "Crystal book service is available." }
      else
        Log.error { "Sorry, Crystal book service is not available!" }
      end
    end

    def launch_playground
      Log.info { "Try to start Crystal playground process ..." }
      success = CmdLine.daemonize "/usr/bin/crystal", ["play", "--port", @playground_port]
      if success
        Log.info { "Started a new Crystal playgound process." }
      else
        Log.error { "Couldn't start a new Crystal playground process!" }
      end
      #
      Log.info { "Try to connect Crystal playground socket ..." }
      if CmdLine.with_retries(10) { CmdLine.server_socket_connectable? "localhost", @playground_port.to_i }
        Log.info { "Crystal playground socket is connectable." }
      else
        Log.error { "Sorry, Crystal playgound socket isn't connectable!" }
      end
      #
      Log.info { "Check Crystal playground service ..." }
      if CmdLine.with_retries(3) { CmdLine.service_available? "localhost", @playground_port.to_i }
        Log.info { "Crystal playground service is available." }
      else
        Log.error { "Sorry, Crystal playground service is not available!" }
      end
    end

    def launch_vscode
      Log.info { "Try to start VSCode editor ...." }
      success = CmdLine.daemonize "/usr/bin/code", [
        "--disable-gpu",
        "--no-xshm",
        "--extensions-dir", "/opt/vscode-extensions" 
      ]
      if success
        Log.info { "Started a new VSCode process." }
      else
        Log.error { "Sorry, can't start a new VSCode process!" }
      end
    end

    def run
      if @reference
        Log.info { STAR_LINE }
        Log.info { "Launch Crystal book service (language reference) and open UI in browser tab ..." }
        Log.info { STAR_LINE }
        launch_reference
        CmdLine.open_in_browser @browser, "http://localhost:8000"
      end
      if @api
        Log.info { STAR_LINE }
        Log.info { "Open Crystal API documentation in browser tab ..." }
        Log.info { STAR_LINE }
        docs_entrypoint = "/opt/crystal-docs/index.html"
        if File.exists? docs_entrypoint
          CmdLine.open_in_browser @browser, "file://#{docs_entrypoint}"
        else
          Log.error { "Sorry, doc's entrypoint file #{docs_entrypoint} is not available!" }
        end
      end
      if @playground
        Log.info { STAR_LINE }
        Log.info { "Launch Crystal playground service and open UI in browser tab ..." }
        Log.info { STAR_LINE }
        launch_playground
        CmdLine.open_in_browser @browser, "http://localhost:#{@playground_port}"
      end
      if @vscode
        Log.info { STAR_LINE }
        Log.info { "Launch VSCode IDE (extensions for Crystal already available)..." }
        Log.info { STAR_LINE }
        launch_vscode
      end
    rescue exc : Exception
      Log.fatal(exception: exc) { "Bad situation!" }
    end
  end
end
