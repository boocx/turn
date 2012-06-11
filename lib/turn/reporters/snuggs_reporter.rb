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

      @squasher = { }

      # @FIXME (y8): Why we need to capture stdout and stderr?

      @stdout = StringIO.new
      @stderr = StringIO.new

      #files  = suite.collect{ |s| s.file }.join(' ')

      io.puts '=' * 78
    end

    def indent
      '  ' * ( @contexts.length - 1 )
    end

    def hash
      @contexts.collect { |c| c.hash }.join(':')
    end

    def squash
      @squasher[hash] = true
    end

    def squashed
      @squasher[hash]
    end

    def start_case kase
      @contexts = []

      kase.name.split('::').each do |context|
        context.gsub! /^\s+/,''

        @contexts << context

        unless squashed
          squash
          io.puts indent + context
        end
      end
    end

    def start_test test
      # @FIXME: Should we move naturalized_name to test itself?
      @contexts << naturalized_name(test).gsub(/^\s\d+/, '')

      io.print "%-74s" % ( indent + @contexts.last )

      @stdout.rewind
      @stderr.rewind

      $stdout = @stdout
      $stderr = @stderr unless $DEBUG
    end

    def pass message=nil
      io.puts PASS
      io.puts

      if message
        message = message.magenta
        message = message.to_s.tabto(TAB_SIZE)
        io.puts(message)
      end
    end

    def fail assertion
      io.puts FAIL
      io.puts

      message = []
      message << ANSI.bold { assertion.message.to_s }
      message << "Assertion at:"
      message << clean_backtrace(assertion.backtrace).join("\n")
      message = message.join("\n")

      io.puts(message.tabto(TAB_SIZE))
    end

    def error exception
      io.puts ERROR
      io.puts

      message = []
      message << ANSI.bold { exception.message }
      message << "Exception `#{exception.class}' at:"
      message << clean_backtrace(exception.backtrace).join("\n")
      message = message.join("\n")

      io.puts(message.tabto(TAB_SIZE))
    end

    def skip(exception)
      io.puts ANSI.yellow { 'SKIP' }

      message = exception.message

      io.puts( '  ' * ( @contexts.length ) + message + "\n\n" )
    end

    def finish_test(test)
      show_captured_output

      $stdout = STDOUT
      $stderr = STDERR
    end

    def add_problem(problem)
      @problems << problem
    end

    def print_problems
    end

    def show_captured_output
      @stdout.rewind

      unless @stdout.eof?
        out = <<-output

STDOUT:
#{@stdout.read}
        output

        STDOUT.puts out.tabto(8)

      end

      @stderr.rewind

      unless @stderr.eof?
        out = <<-output

STDERR:
#{@stderr.read}
        output

        STDERR.puts out.tabto(8)
      end
    end

    def finish_suite(suite)
      total      = suite.count_tests
      passes     = suite.count_passes
      assertions = suite.count_assertions
      failures   = suite.count_failures
      errors     = suite.count_errors
      skips      = suite.count_skips

      bar = '=' * 78

      bottom = [bar]
      bottom << "  pass: %d,  fail: %d,  error: %d, skip: %d" % [passes, failures, errors, skips]
      bottom << "  total: %d tests with %d assertions in %f seconds" % [total, assertions, (Time.new - @time)]
      bottom << bar

      color = if ( failures + skips + errors ) == 0
                :green
              elsif ( failures + errors ) == 0
                :yellow
              else
                :red
              end

      bottom.each do |line|
        io.puts paint(line, color)
      end
    end

    def paint line, color
      ANSI.__send__(color) { line }
    end
  end
end
