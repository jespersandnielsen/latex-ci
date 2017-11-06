require 'octokit'

module GithubClient
  def self.client
    Octokit::Client.new(access_token: ENV['TOKEN'])
  end
end
