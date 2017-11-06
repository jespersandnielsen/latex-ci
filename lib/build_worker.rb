require 'sidekiq'
require './github_client'
require './repo_builder'

Sidekiq.configure_server do |config|
  config.redis = { url: "redis://#{ENV['REDIS_HOST']}:#{ENV['REDIS_PORT']}" }
end

class BuildWorker
  include Sidekiq::Worker

  def initialize(gh_client = GithubClient.client)
    @gh_client = gh_client
  end

  def perform(params)
    repo_builder = RepoBuilder.new(@gh_client, params).build
  end

end
