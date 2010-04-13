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
        output.must_match /Halloooooo!/
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
        output.must_match(/ 1 skips/)
        output.must_match(/Skipped:\ntest_0001_should_be_reported_as_a_skipped_spec/)
      end
    end
  end
end
