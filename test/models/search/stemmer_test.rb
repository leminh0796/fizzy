require "test_helper"

class Search::StemmerTest < ActiveSupport::TestCase
  test "stem single word" do
    result = Search::Stemmer.stem("running")

    assert_equal "run", result
  end

  test "stem multiple words" do
    result = Search::Stemmer.stem("test, running      JUMPING & walking")

    assert_equal "test run jump walk", result
  end
end
