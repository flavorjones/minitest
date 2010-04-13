require 'minitest/spec'
require 'tempfile'

MiniTest::Unit.autorun

describe "MiniTest::Spec meta" do

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
    describe "run_spec" do
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

      it "should return success if successful" do
        output, exit_code = run_spec do
          describe "embedded spec" do
            it "should succeed" do
              assert true
            end
          end
        end
        assert exit_code.success?
      end

      it "should return failure if failed" do
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

  describe "the report" do
    describe "when there is no block passed to 'it'" do
      it "should report a skipped spec" do
        output, exit_code = run_spec do
          describe "blockless it" do
            it "should be reported as a skipped spec"
          end
        end
        output.must_match(/\b1 skips/)
        output.must_match(/Skipped:\ntest_0001_should_be_reported_as_a_skipped_spec/)
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
            it("should run me") { assert true }
            it("should run me") { assert true }
          end
        end
        output.must_match(/\b2 assertions/)
      end
    end

    describe "within nested describes" do
      it "should run both specs" do
        output, exit_code = run_spec do
          describe "Level 1" do
            describe "Level 2a" do
              it("should run me") { assert true }
            end
            describe "Level 2b" do
              it("should run me") { assert true }
            end
          end
        end
        output.must_match(/\b2 tests/)
      end
    end
  end

  describe "inheritance" do
    it "will be avoided" do
      output, exit_code = run_spec do
        describe "Level 1" do
          it "should only run once" do
            assert true
          end
          describe "Level 2" do
            it "has a test" do
              assert true
            end
          end
          it "should also only run once" do
            assert false
          end
        end
      end
      output.must_match(/\b3 tests/)
    end
  end

  # describe "specifications in the report" do
  #   it "prints specifications for skipped tests" do
  #     output, exit_code = run_spec do
  #       describe "on a skipped spec" do
  #         describe "the report" do
  #           it "should print the specification in the report"
  #         end
  #       end
  #     end
  #     output.must_match /Skipped:\non a skipped spec the report should print the specification in the report/
  #   end

  #   it "prints specifications for failed tests" do
  #     output, exit_code = run_spec do
  #       describe "on a failed spec" do
  #         describe "the report" do
  #           it "should print the specification in the report" do
  #             assert false
  #           end
  #         end
  #       end
  #     end
  #     output.must_match /Skipped:\non a failed spec the report should print the specification in the report/
  #   end

  #   it "prints specifications for tests with errors" do
  #     output, exit_code = run_spec do
  #       describe "on a spec with errors" do
  #         describe "the report" do
  #           it "should print the specification in the report" do
  #             raise "HELL"
  #           end
  #         end
  #       end
  #     end
  #     output.must_match /Skipped:\non a spec with errors the report should print the specification in the report/
  #   end
  # end
end
