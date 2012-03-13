require 'turn/reporter'
require 'stringio'

module Turn
  # TODO: Should we fit reporter output to width of console?
  #       y8: Yes. we should, but it's a kinda tricky, if you want to make it
  #           cross-platform.
  # (See https://github.com/cldwalker/hirb/blob/master/lib/hirb/util.rb#L61)

  class SnuggsReporter < Reporter
    TAB_SIZE = 8
    TAB = "  "

    def start_suite suite
      @problems = []
      @suite    = suite
      @time     = Time.now

      # @FIXME (y8): Why we need to capture stdout and stderr?

      @stdout = StringIO.new
      @stderr = StringIO.new

      #files  = suite.collect{ |s| s.file }.join(' ')

      io.puts '=' * 78

      if suite.seed
        io.puts "MorSnuggs #{suite.name} (SEED #{suite.seed})"
      else
        io.puts "MorSnuggs #{suite.name}"
      end

      io.puts '=' * 78
    end

    def start_case kase
      @indentation = ""

      formatted_kase_name = kase.name.split('::').inject("") do |result, desc|
        result       += "\n#{ @indentation + desc }"
        @indentation += TAB
        result
      end

      io.puts( formatted_kase_name.bold ) if kase.size > 0
    end

    def start_test test
      # @FIXME: Should we move naturalized_name to test itself?
      name = naturalized_name(test).gsub(/^\s\d+/, @indentation)

      io.print "%-57s" % name

      @stdout.rewind
      @stderr.rewind

      $stdout = @stdout
      $stderr = @stderr unless $DEBUG
    end

    def pass message=nil
      io.puts " %s %s" % [ticktock, PASS]

      if message
        message = message.magenta
        message = message.to_s.tabto(TAB_SIZE)
        io.puts(message)
      end
    end

    def fail assertion
      io.puts " %s %s" % [ticktock, FAIL]

      message = []
      message << Colorize.bold(assertion.message.to_s)
      message << "Assertion at:"
      message << clean_backtrace(assertion.backtrace).join("\n")
      message = message.join("\n")

      io.puts(message.tabto(TAB_SIZE))

      #unless backtrace.empty?
      #  io.puts "Assertion at".tabto(TAB_SIZE)
      #  io.puts backtrace.map{|l| l.tabto(TAB_SIZE)}.join("\n")
      #end

      #io.puts "STDERR:".tabto(TAB_SIZE)
      show_captured_output
    end

    def error exception
      io.puts " %s %s" % [ticktock, ERROR]

      message = []
      message << exception.message.bold
      message << "Exception `#{exception.class}' at:"
      message << clean_backtrace(exception.backtrace).join("\n")
      message = message.join("\n")

      io.puts(message.tabto(TAB_SIZE))

      show_captured_output
    end

    def skip(exception)
      io.puts " %s %s" % [ticktock, SKIP]

      message = exception.message

      io.puts(message.tabto(8))

      show_captured_output
    end

    def finish_test(test)
      $stdout = STDOUT
      $stderr = STDERR
    end

    def add_problem(problem)
      @problems << problem
    end

    def print_problems
    end

    def show_captured_output
      show_captured_stdout
    end

    def show_captured_stdout
      @stdout.rewind

      return if @stdout.eof?

      STDOUT.puts(<<-output.tabto(8))
\nSTDOUT:
#{@stdout.read}
      output
    end

    # TODO: pending (skip) counts
    def finish_suite(suite)
      total      = suite.count_tests
      passes     = suite.count_passes
      assertions = suite.count_assertions
      failures   = suite.count_failures
      errors     = suite.count_errors
      skips      = suite.count_skips

      bar = '=' * 78

      bar = pass == total ? bar.green : bar.red

      # @FIXME: Should we add suite.runtime, instead if this lame time calculations?
      tally = [total, assertions, (Time.new - @time)]

      io.puts bar
      io.puts "  pass: %d,  fail: %d,  error: %d, skip: %d" % [passes, failures, errors, skips]
      io.puts "  total: %d tests with %d assertions in %f seconds" % tally
      io.puts bar
    end
  end
end
