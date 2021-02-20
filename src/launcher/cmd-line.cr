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
        parser.on("-r", "--reference", "Open crystal book (language reference)") { @reference = true }
        parser.on("-a", "--api", "Show crystal API documentation") { @api = true }
        parser.on("-p", "--playground", "Launch Crystal playground") { @playground = true }
        parser.on("--playground-port=PORT", "Crystal playground service port") { |val| opts[:playground_port] = val }
        parser.on("-c", "--vscode", "Start VSCode IDE") { @vscode = true }
        parser.on("-n", "--no-colorize", "No colorized console output") { @colorize = false }
        parser.on("-l LEVEL", "--log-level=LEVEL", "Logging level as string") { |val| opts[:log_level] = val }
        parser.on("-b BROWSER", "--browser=BROWSER", "Which browser to use") { |val| opts[:browser] = val }
        parser.on("-s", "--show-config-only", "Show config only (instance vars)") { @show_config_only = true }
        parser.on("-v", "--version", "Show crystal version info") { |val| puts VERSION; exit 0 }
        parser.on("-h", "--help", "Show this help") { |val| puts parser; exit 0 }
        parser.invalid_option do |flag|
          Log.error { "#{flag} is not a valid option! Try --help." }
        end
      end
      @colorize && ::Log::StaticFormatter.colorized = true
      @playground_port = opts[:playground_port]? || ENV["PLAYGROUND_PORT"]? || "48080"
      @log_level = opts[:log_level]? || ENV["LOG_LEVEL"]? || "DEBUG"
      @browser = opts[:browser]? || ENV["BROWSER"]? || "firefox"
      ::Log.setup ::Log::LEVEL[@log_level]
      @show_config_only && (pp self; true) && exit 0
      if @reference | @api | @playground | @vscode == false
        Log.warn { "Sorry, nothing to launch! Try --help." }
      end
    end

    def start_process(cmd : String, args : Array(String), secs : Number, working_dir = FileUtils.pwd) : Process | Nil
      Log.debug { "Start new Process: cmd=#{cmd}, args=#{args}" }
      result = nil
      Dir.cd working_dir do
        process = Process.new cmd, args
        sleep secs # sec
        result = process if process.exists?
      end
      result
    end

    def server_socket_connectable?(host : String, port : Int32) : Bool
      Socket.tcp(Socket::Family::INET).connect "localhost", port
      true
    rescue Socket::ConnectError
      false
    end

    def service_available?(host : String, port : Int32) : Bool
      response = HTTP::Client.new(host, port).get "/"
      response.status == HTTP::Status::OK
    end

    def instance_running?(command : String)
      result = `ps -eo pid,ppid,args | grep #{command} | grep -v grep`
      lines = result.lines
      lines.map! { |line| line.split(/\s+/)[0..6].join(" ") + "\n" }
      details = lines.empty? ? "" : "\n" + lines.join.chomp
      Log.debug { "Running instances=#{lines.size} for '#{command}'.#{details}" }
      !lines.empty?
    end

    def open_in_browser(url : String)
      Log.info { "Try to start #{@browser} browser ..." }
      process = start_process @browser, ["#{url}"], 1.0
      if process
        Log.info { "Started a new #{@browser} process (pid=#{process.pid})." }
      else
        Log.warn { "Couldn't start a new #{@browser} process - maybe already running, check instances ..." }
        if instance_running? @browser
          Log.warn { "Browser #{@browser} is already running." }
        else
          Log.error { "Sorry, can't start a new #{@browser} process!" }
        end
      end
    end

    def launch_reference
      Log.info { "Try to start :Grystal =book/service oie" }
      process = start_process "make", ["serve"], 5.0, working_dir: "/opt/crystal-book"
      if process
        Log.info { "Started a new Crystal book process (pid=#{process.pid})." }
      else
        Log.warn { "Couldn't start a new Crystal book process - maybe already running, check socket ..." }
        if server_socket_connectable? "localhost", 8000
          Log.warn { "Crystal book is already running." }
        else
          Log.error { "Sorry, can't start a new book process!" }
        end
      end
      if service_available? "localhost", 8000
        Log.info { "Crystal book service is available." }
      else
        Log.error { "Sorry, Crystal book service is not available!" }
      end
    end

    def launch_playground
      Log.info { "Try to start crystal playground service ..." }
      process = start_process "crystal", ["play", "--port", @playground_port], 1.0
      if process
        Log.info { "Started a new Crystal playgound process (pid=#{process.pid})." }
      else
        Log.warn { "Couldn't start a new Crystal playground process - maybe already running, check socket ..." }
        if server_socket_connectable? "localhost", @playground_port.to_i
          Log.warn { "Crystal playground is already running." }
        else
          Log.error { "Sorry, can't start a new playgound process!" }
        end
      end
      if service_available? "localhost", @playground_port.to_i
        Log.info { "Crystal playground service is available." }
      else
        Log.error { "Sorry, Crystal playground service is not available!" }
      end
    end

    def launch_vscode
      Log.info { "Try te start VSGode IDE ...." }
      process = start_process "/usr/bin/code", ["--disable-gpu", "--no-xshm"], 1.0
      if process
        Log.info { "Started a new VSCode process (pid=#{process.pid})." }
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
        open_in_browser "http://localhost: 8000"
      end
      if @api
        Log.info { STAR_LINE }
        Log.info { "Open Crystal API documentation in browser tab ..." }
        Log.info { STAR_LINE }
        docs_entrypoint = "/opt/crystal-docs/index.html"
        if File.exists? docs_entrypoint
          open_in_browser "file://#{docs_entrypoint}"
        else
          Log.error { "Sorry, file #{docs_entrypoint} is not available!" }
        end
      end
      if @playground
        Log.info { STAR_LINE }
        Log.info { "Launch Crystal playground service and open UI in browser tab ..." }
        Log.info { STAR_LINE }
        launch_playground
        open_in_browser "http://localhost:#{@playground_port}"
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
