class User::DayTimeline
  attr_reader :user, :day, :filter

  def initialize(user, day, filter)
    @user, @day, @filter = user, day, filter
  end

  def has_activity?
    events.any?
  end

  def events
    filtered_events.where(created_at: window).order(created_at: :desc)
  end

  def next_day
    latest_event_before&.created_at
  end

  def collections
    filter.collections.presence || user.collections
  end

  def earliest_time
    next_day&.tomorrow&.beginning_of_day
  end

  def latest_time
    day.yesterday.beginning_of_day
  end

  private
    def filtered_events
      @filtered_events ||= Event.where(collection: collections)
    end

    def latest_event_before
      filtered_events.where(created_at: ...day.beginning_of_day).chronologically.last
    end

    def window
      day.all_day
    end
end
