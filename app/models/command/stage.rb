class Command::Stage < Command
  include Command::Cards

  store_accessor :data, :stage_id, :original_stage_ids_by_card_id

  validates_presence_of :stage

  def title
    "Move #{cards_description} to stage '#{stage&.name || stage_id}'"
  end

  def execute
    original_stage_ids_by_card_id = {}

    transaction do
      cards.find_each do |card|
        next unless card_compatible_with_stage?(card)

        original_stage_ids_by_card_id[card.id] = card.stage_id
        card.change_stage_to stage
      end

      update! original_stage_ids_by_card_id: original_stage_ids_by_card_id
    end
  end

  def undo
    transaction do
      affected_cards_by_id = user.accessible_cards.where(id: original_stage_ids_by_card_id.keys).index_by(&:id)
      stages_by_id = Workflow::Stage.where(id: original_stage_ids_by_card_id.values).uniq.index_by(&:id)

      original_stage_ids_by_card_id.each do |card_id, original_stage_id|
        card = affected_cards_by_id[card_id.to_i]
        stage = stages_by_id[original_stage_id.to_i]

        next unless card && stage

        card.change_stage_to stage
      end
    end
  end

  private
    def stage
      Workflow::Stage.find_by(id: stage_id)
    end

    def card_compatible_with_stage?(card)
      stage&.workflow && card.collection.workflow == stage.workflow
    end

    def closed_cards
      user.accessible_cards.where(id: closed_card_ids)
    end
end
