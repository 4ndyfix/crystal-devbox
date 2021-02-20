require "./launcher/cmd-line"
require "./launcher/web-service"

module DevboxLauncher
  VERSION = File.basename(PROGRAM_NAME).capitalize + " version: " +
            {{ `git describe --long; crystal -v`.stringify.gsub(/\n+/, "\n") }}

  enum Mode
    CLI
    UI
  end

  MODE = "MODE"

  ENV[MODE] = Mode::CLI.to_s unless ENV.has_key? MODE
  case ENV[MODE]
  when Mode::CLI.to_s then DevboxLauncher::CmdLine.new.run
  when Mode::UI.to_s  then DevboxLauncher::WebService.up
  else                     raise "Sorry, invalid value for env var MODE - must be '#{Mode::CLI}' or '#{Mode::UI}'!"
  end
end
