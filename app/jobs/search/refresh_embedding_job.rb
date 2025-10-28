class Search::RefreshEmbeddingJob < ApplicationJob
  retry_on RubyLLM::ForbiddenError
  discard_on ActiveJob::DeserializationError

  def perform(record)
    record.refresh_search_embedding
  end
end
