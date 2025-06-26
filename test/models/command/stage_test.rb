require "test_helper"

class Command::StageTest < ActionDispatch::IntegrationTest
  include CommandTestHelper

  setup do
    Current.session = sessions(:david)
    @card = cards(:text)
    @new_stage = workflow_stages(:qa_review)
    @original_stage = @card.stage
  end

  test "move card to a new stage on perma" do
    assert_changes -> { @card.reload.stage }, from: @original_stage, to: @new_stage do
      execute_command "/stage #{@new_stage.name}", context_url: collection_card_url(@card.collection, @card)
    end
  end

  test "move cards on cards' index page" do
    cards = [ cards(:logo), cards(:layout), cards(:text) ]

    execute_command "/stage #{@new_stage.name}", context_url: collection_cards_url(@card.collection)

    cards.each do |card|
      assert_equal @new_stage, card.reload.stage
    end
  end

  test "undo stage change" do
    cards = [ cards(:logo), cards(:layout), cards(:text) ]
    cards.each { it.change_stage_to @original_stage }

    command = parse_command "/stage #{@new_stage.name}", context_url: collection_cards_url(@card.collection)
    command.execute

    cards.each do |card|
      assert_equal @new_stage, card.reload.stage
    end

    command.undo

    # Verify cards moved back to original stages
    cards.each do |card|
      assert_equal @original_stage, card.reload.stage
    end
  end
end
