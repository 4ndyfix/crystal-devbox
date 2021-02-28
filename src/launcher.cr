require "./launcher/cmd-line"
require "./launcher/web-service"

module DevboxLauncher
  VERSION = File.basename(PROGRAM_NAME).capitalize + " version: " +
            {{ `git describe --long; crystal -v`.stringify.gsub(/\n+/, "\n") }}

  MODE = "MODE"
  ENV[MODE] = "CLI" unless ENV.has_key? MODE
  case ENV[MODE]
  when "CLI" then DevboxLauncher::CmdLine.new.run
  when "UI" then DevboxLauncher::WebService.up
  else raise "Sorry, invalid value for env var MODE - must be 'CLI' or 'UI'!"
  end
end
