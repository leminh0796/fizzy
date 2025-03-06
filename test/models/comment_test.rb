require "test_helper"

class CommentTest < ActiveSupport::TestCase
  setup do
    Current.session = sessions(:david)
  end

  test "searchable by body" do
    message = bubbles(:logo).capture Comment.new(body: "I'd prefer something more rustic")

    assert_includes Comment.search("something rustic"), message.comment
  end

  test "updating bubble counter" do
    assert_difference -> { bubbles(:logo).comments_count } do
      assert_changes -> { bubbles(:logo).activity_score } do
        bubbles(:logo).capture Comment.new(body: "I'd prefer something more rustic")
      end
    end

    assert_difference -> { bubbles(:logo).comments_count }, -1 do
      assert_changes -> { bubbles(:logo).activity_score } do
        bubbles(:logo).messages.comments.last.destroy
      end
    end
  end

  test "first_by_author_on_bubble?" do
    assert_not Comment.new.first_by_author_on_bubble?

    with_current_user :david do
      comment = Comment.new.tap { |c| bubbles(:logo).capture c }
      assert comment.first_by_author_on_bubble?

      comment = Comment.new.tap { |c| bubbles(:logo).capture c }
      assert_not comment.first_by_author_on_bubble?
    end

    with_current_user :kevin do
      comment = Comment.new.tap { |c| bubbles(:logo).capture c }
      assert_not comment.first_by_author_on_bubble?
    end
  end

  test "follows_comment_by_another_author?" do
    assert_not Comment.new.follows_comment_by_another_author?

    bubble = buckets(:writebook).bubbles.create!

    with_current_user :david do
      comment = Comment.new.tap { |c| bubble.capture c }
      assert_not comment.follows_comment_by_another_author?
    end

    with_current_user :kevin do
      comment = Comment.new.tap { |c| bubble.capture c }
      assert comment.follows_comment_by_another_author?
    end

    with_current_user :david do
      comment = Comment.new.tap { |c| bubble.capture c }
      assert comment.follows_comment_by_another_author?
    end
  end
end
