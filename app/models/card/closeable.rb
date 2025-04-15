module Card::Closeable
  extend ActiveSupport::Concern

  AUTO_CLOSE_AFTER = 30.days
  AUTO_CLOSE_REMINDER = 7.days

  included do
    has_one :closure, dependent: :destroy

    scope :closed, -> { joins(:closure) }
    scope :active, -> { where.missing(:closure) }

    scope :recently_closed_first, -> { closed.order("closures.created_at": :desc) }
    scope :due_to_be_closed, -> { considering.where(last_active_at: ..AUTO_CLOSE_AFTER.ago) }
  end

  class_methods do
    def auto_close_all_due
      due_to_be_closed.find_each do |card|
        card.close(user: User.system, reason: "Closed")
      end
    end
  end

  def auto_close_at
    last_active_at + AUTO_CLOSE_AFTER if last_active_at
  end

  def auto_close_days_until
    return false unless auto_close_at
    (auto_close_at.to_date - Date.today).to_i
  end

  def auto_close_remind?
    auto_close_days_until <= AUTO_CLOSE_REMINDER / 1.day
  end

  def closed?
    closure.present?
  end

  def active?
    !closed?
  end

  def closed_by
    closure&.user
  end

  def closed_at
    closure&.created_at
  end

  def close(user: Current.user, reason: Closure::Reason::FALLBACK_LABEL)
    unless closed?
      transaction do
        create_closure! user: user, reason: reason
        track_event :closed, creator: user
      end
    end
  end

  def reopen
    closure&.destroy
  end
end
