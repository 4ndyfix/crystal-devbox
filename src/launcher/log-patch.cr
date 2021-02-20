require "log"
require "colorize"

# A Little bit of monkey-patching for colored logging ;-)
class Log
  struct StaticFormatter
    @color : Symbol
    @@colorized = false

    def self.colorized=(colorized : Bool)
      @@colorized = colorized
    end

    def self.colorized
      @@colorized
    end

    def initialize(@entry : Log::Entry, @io : IO)
      @color = case @entry.severity
               when Log::Severity::Debug then :dark_gray
               when Log::Severity::Info  then :light_green
               when Log::Severity::Warn  then :light_yellow
               when Log::Severity::Error then :light_red
               when Log::Severity::Fatal then :light_magenta
               else                           :white
               end
    end

    def timestamp
      @io << @entry.timestamp.to_rfc3339(fraction_digits: 3).colorize(@color).toggle(StaticFormatter.colorized)
    end

    def severity
      just_val = StaticFormatter.colorized ? 15 : 6
      @entry.severity.label.colorize(@color).toggle(StaticFormatter.colorized).to_s.rjust(@io, just_val)
    end

    def source(*, before = nil, after = nil)
      if @entry.source.size > 0
        @io << before.colorize(@color).toggle(StaticFormatter.colorized)
        @io << @entry.source.colorize(@color).toggle(StaticFormatter.colorized)
        @io << after.colorize(@color).toggle(StaticFormatter.colorized)
      end
    end

    def message
      @io << @entry.message.colorize(@color).toggle(StaticFormatter.colorized)
    end

    def exception(*, before = '\n', after = nil)
      if ex = @entry.exception
        @io << before.colorize(@color).toggle(StaticFormatter.colorized)
        @io << ex.inspect_with_backtrace.colorize(@color).toggle(StaticFormatter.colorized)
        @io << after.colorize(@color).toggle(StaticFormatter.colorized)
      end
    end
  end

  LEVEL = {
    "DEBUG" => Log::Severity::Debug,
    "INFO"  => Log::Severity::Info,
    "WARN"  => Log::Severity::Warn,
    "ERROR" => Log::Severity::Error,
    "FATAL" => Log::Severity::Fatal,
  }
end

# ##Log::StaticFormatter.colorized = true
