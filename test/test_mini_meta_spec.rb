require 'minitest/spec'
require 'tempfile'

MiniTest::Unit.autorun

describe "meta-MiniTest::Spec" do
  #
  #  run the block (presumably a spec) in a subprocess,
  #  capturing stdout and exit code.
  #
  def run_spec &block
    output = IO.popen("-") do |pipe|
      if pipe
        pipe.read
      else
        MiniTest::Unit::TestCase.reset
        block.call
        exit_code = MiniTest::Unit.new.run(ARGV)
        exit false if exit_code && exit_code != 0
      end
    end
    [output, $?]
  end

  describe "meta meta test" do
    describe "#run_spec" do
      it "should return the output of the spec" do
        output, exit_code = run_spec do
          describe "embedded spec" do
            it "should generate output" do
              puts "Halloooooo!"
            end
          end
        end
        output.must_match(/Halloooooo!/)
      end

      it "should return success if tests pass" do
        output, exit_code = run_spec do
          describe "embedded spec" do
            it "should succeed" do
              assert true
            end
          end
        end
        assert exit_code.success?
      end

      it "should return failure if a test fails" do
        output, exit_code = run_spec do
          describe "embedded spec" do
            it "should fail" do
              assert false
            end
          end
        end
        assert ! exit_code.success?
      end
    end
  end

  # ====================

  describe "reporting" do
    describe "when there is no block passed to 'it'" do
      it "should indicate a skipped spec" do
        output, exit_code = run_spec do
          describe "blockless it" do
            it "should be reported as a skipped spec"
          end
        end
        output.must_match(/\b1 skips/)
      end
    end

    describe "when there is a skipped spec" do
      it "should report the full spec description" do
        output, exit_code = run_spec do
          describe "This is an Outer describe" do
            describe "and This is an Inner describe" do
              it "and This is it"
            end
          end
        end
        output.must_match(/Skipped:\nThis is an Outer describe and This is an Inner describe and This is it/)
      end

      it "should report the line number of the skipped spec" do
        output, exit_code = run_spec do
          describe "foo" do
            it "bar"
          end
        end
        output.must_match %r{Skipped:\nfoo bar \[#{__FILE__}:#{__LINE__ - 3}\]}
      end
    end

    describe "when there is a failed spec" do
      it "should report the full spec description" do
        output, exit_code = run_spec do
          describe "This is an Outer describe" do
            describe "and This is an Inner describe" do
              it "and This is it" do
                assert false
              end
            end
          end
        end
        output.must_match(/Failed:\nThis is an Outer describe and This is an Inner describe and This is it/)
      end

      it "should report the line number of the failed assertion" do
        output, exit_code = run_spec do
          describe "foo" do
            it "bar" do
              assert false
            end
          end
        end
        output.must_match %r{Failed:\nfoo bar \[#{__FILE__}:#{__LINE__ - 4}\]}
      end

      it "should report the message from the failed assertion" do
        output, exit_code = run_spec do
          describe "foo" do
            it "bar" do
              assert false, "don't tread on me."
            end
          end
        end
        output.must_match %r{don\'t tread on me.}
      end
    end

    describe "when there is a spec with an error" do
      it "should report the full spec description" do
        output, exit_code = run_spec do
          describe "This is an Outer describe" do
            describe "and This is an Inner describe" do
              it "and This is it" do
                raise "HELL"
              end
            end
          end
        end
        output.must_match(/Error:\nThis is an Outer describe and This is an Inner describe and This is it/)
      end

      it "should report the line number of the error" do
        output, exit_code = run_spec do
          describe "foo" do
            it "bar" do
              raise "HELL"
            end
          end
        end
        output.must_match %r{Error:\nfoo bar \[#{__FILE__}:#{__LINE__ - 4}\]}
      end

      it "should report the message from the exception" do
        output, exit_code = run_spec do
          describe "foo" do
            it "bar" do
              raise "don't tread on me."
            end
          end
        end
        output.must_match %r{don\'t tread on me.}
      end

      it "should report the backtrace from the exception" do
        output, exit_code = run_spec do
          describe "foo" do
            def exception_nesting_1
              exception_nesting_2
            end

            def exception_nesting_2
              raise "HELL"
            end

            it "bar" do
              exception_nesting_1
            end
          end
        end
        output.must_match %r{#{__FILE__}:#{__LINE__ - 12}:in \`exception_nesting_1\'}
        output.must_match %r{#{__FILE__}:#{__LINE__ - 9}:in \`exception_nesting_2\'}
        output.must_match %r{#{__FILE__}:#{__LINE__ - 6}:in \`test_0001_bar\'}
      end
    end
  end

  describe "two describes with the same description" do
    it "should run both blocks" do
      output, exit_code = run_spec do
        describe "Foo" do
          it "should run this" do
            assert true
          end
        end
        describe "Foo" do
          it "should also run this" do
            assert true
          end
        end
      end
      output.must_match(/\b2 tests/)
    end
  end

  describe "two 'it's with the same description" do
    describe "within the same describe" do
      it "should run both specs" do
        output, exit_code = run_spec do
          describe "Level 1" do
            it "should run me" do
              assert true
            end
            it "should run me" do
              assert true
            end
          end
        end
        output.must_match(/\b2 tests, 2 assertions/)
      end
    end

    describe "within nested describes" do
      it "should run both specs" do
        output, exit_code = run_spec do
          describe "Level 1" do
            describe "Level 2a" do
              it "should run me" do
                assert true
              end
            end
            describe "Level 2b" do
              it "should run me" do
                assert true
              end
            end
          end
        end
        output.must_match(/\b2 tests/)
      end
    end
  end

  describe "inheritance" do
    it "will be avoided, part 0" do
      output, exit_code = run_spec do
        describe "Level 1" do
          describe "Level 2" do
            it "unrelated test" do
              assert true
            end
          end
          it "should only run once" do
            assert false
          end
        end
      end
      output.must_match(/\b2 tests, 2 assertions, 1 failure/)
    end

    it "will be avoided, part 1" do
      output, exit_code = run_spec do
        describe "Level 1" do
          it "should only run once" do
            assert true
          end
          describe "Level 2" do
            it "should only run once" do
              assert false
            end
          end
        end
      end
      output.must_match(/\b2 tests, 2 assertions, 1 failure/)
    end

    it "will be avoided, part 2" do
      output, exit_code = run_spec do
        describe "Level 1" do
          describe "Level 2" do
            it "should only run once" do
              assert false
            end
          end
          it "should only run once" do
            assert true
          end
        end
      end
      output.must_match(/\b2 tests, 2 assertions, 1 failure/)
    end
  end
end
