require 'sidekiq'
require 'sinatra'
require 'json'
require './github_client'
require_relative 'lib/build_worker'

batch_file_types = %w(svg)
build_context = "latex-ci-build"

Sidekiq.configure_client do |config|
  config.redis = { url: "redis://#{ENV['REDIS_HOST']}:#{ENV['REDIS_PORT']}" }
end

before do
  @gh_client ||= GithubClient.client
end

get '/' do
  'Latex-CI'
end

post '/build' do
  payload = JSON.parse params[:payload]

  data = {
    id: payload['head_commit']['id'],
    repo: payload['repository'],
    branch: payload['ref'][/([^\/]+)$/],
    event_type: request.env['HTTP_X_GITHUB_EVENT'],
    build_context: build_context
  }

  BuildWorker.perform_async(data)

  return
end

get '/:owner/:repo.:file_type' do
  @file_type = params[:file_type]
  owner = params[:owner]
  repo = params[:repo]
  branch = params[:branch]

  content_type @file_type
  not_found unless batch_file_types.include? @file_type

  statuses = @gh_client.combined_status("#{owner}/#{repo}", branch).where(context: build_context)

  p statuses

  state = statuses.last[:state] if statuses.respond_to?(:last)
  state = :success if state.nil?

  @build_status = case state
    when :failure then :failing
    when :error then :failing
    when :success then :passing
  end

  render_view :batch
end

def render_view(view)
  erb "#{view}.#{@file_type}".to_sym
end

not_found do
  status 404
end
