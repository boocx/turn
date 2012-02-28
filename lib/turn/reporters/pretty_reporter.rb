require 'turn/reporter'

module Turn
  # = Pretty Reporter (by Paydro)
  #
  # Example output:
  #    TestCaseName:
  #         PASS test: Succesful test case.  (0.03s)
  #        ERROR test: Bogus test case.  (0.04s)
  #         FAIL test: Failed test case.  (0.03s)
  #
  class PrettyReporter < Reporter
    # Second column left padding in chars.
    TAB_SIZE = 10

    # Character to put in front of backtrace.
    TRACE_MARK = '@ '

    # At the very start, before any testcases are run, this is called.
    def start_suite(suite)
      @suite  = suite
      @time   = Time.now

      #io.puts
      io.puts Colorize.bold("Loaded Suite '#{suite.name}'")
      io.puts
      io.puts "Started at #{Time.now} w/ seed #{suite.seed}."
      io.puts
    end

    # Invoked before a testcase is run.
    def start_case(kase)
      # Print case name if there any tests in suite
      # TODO: Add option which will show all test cases, even without tests?
      io.puts kase.name if kase.size > 0
    end

    # Invoked before a test is run.
    def start_test(test)
      @test_time = Time.now
      @test = test
    end

    # Invoked when a test passes.
    def pass(message=nil)
      banner PASS

      if message
        message = Colorize.magenta(message)
        message = message.to_s.tabto(TAB_SIZE)

        io.puts(message)
      end
    end

    # Invoked when a test raises an assertion.
    def fail(assertion, message=nil)
      banner FAIL

      prettify(message, assertion)
    end

    # Invoked when a test raises an exception.
    def error(exception, message=nil)
      banner ERROR

      prettify(message, exception)
    end

    # Invoked when a test is skipped.
    def skip(exception, message=nil)
      banner SKIP

      prettify(message, exception)
    end

    # Invoked after all tests in a testcase have ben run.
    def finish_case(kase)
      # Print newline is there any tests in suite
      io.puts if kase.size > 0
    end

    # After all tests are run, this is the last observable action.
    def finish_suite(suite)
      total      = "%d tests" % suite.count_tests
      passes     = "%d passed" % suite.count_passes
      assertions = "%d assertions" % suite.count_assertions
      failures   = "%d failures" % suite.count_failures
      errors     = "%d errors" % suite.count_errors
      skips      = "%d skips" % suite.count_skips

      io.puts "Finished in %.6f seconds." % (Time.now - @time)
      io.puts

      io.puts [ Colorize.bold(total),
                Colorize.pass(passes),
                Colorize.fail(failures),
                Colorize.error(errors),
                Colorize.skip(skips),
                assertions
              ].join(", ")
      #io.puts
    end

  private
    # Outputs test case header for given event (error, fail & etc)
    #
    # Example:
    #    PASS test: Test decription.  (0:00:02:059)
    def banner(event)
      #io.puts "%18s %s (%.2fs)" % [event, @test, Time.now - @test_time]
      io.puts "%18s %s (%s)" % [event, @test, ticktock]
    end

    # Cleanups and prints test payload
    def prettify(message=nil, raised)
      # Get message from raised, if not fiven
      message ||= raised.message

      backtrace = raised.respond_to?(:backtrace) ? raised.backtrace : raised.location

      # Filter and clean backtrace
      backtrace = clean_backtrace(backtrace)

      #io.puts
      io.puts Colorize.bold(message.tabto(TAB_SIZE))
      #io.puts
      io.puts (TRACE_MARK + backtrace[0]).tabto(TAB_SIZE)
      io.puts backtrace[1..-1].join("\n").tabto(TAB_SIZE+2)
      io.puts
    end
  end
end
