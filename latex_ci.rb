require 'sinatra'
require 'json'
require 'git'
require 'octokit'

batch_file_types = %w(svg)

before do
  @gh_client ||= Octokit::Client.new(access_token: ENV['TOKEN'])
end

get '/' do
  'Latex-CI'
end

post '/build' do
  payload = JSON.parse params[:payload]
  repo = payload['repository']
  branch = payload['ref'][/([^\/]+)$/]
  event_type = request.env['HTTP_X_GITHUB_EVENT']

  @gh_client.create_status(@repo['full_name'], @payload['head_commit']['id'], 'pending')

  case event_type
  when 'push'
    pull_repo repo, branch
    exitcode = build_repo repo, branch
  end

  return
end

get '/:owner/:repo.:file_type' do
  @file_type = params[:file_type]
  owner = params[:owner]
  repo = params[:repo]
  branch = params[:branch]

  content_type @file_type
  not_found unless batch_file_types.include? @file_type

  # status = @gh_client.combined_status "#{owner}/#{repo}", branch

  # p status

  @build_status = :passing
  # @build_status = :failing

  render_view :batch
end

def pull_repo(repo, branch)
  repo_dir = "builds/#{repo['name']}/#{branch}"
  repo_url = repo['url']

  if File.directory? repo_dir
    g = Git.open repo_dir
    g.pull
  else
    g = Git.clone repo_url, repo_dir
  end
end

def build_repo(repo, branch)
  repo_dir = "builds/#{repo['name']}/#{branch}"

  Dir.chdir repo_dir

  system 'latexmk -c'
  system 'latexmk -interaction=nonstopmode -halt-on-error > log.txt'

  @gh_client.create_status(@repo['full_name'], @payload['head_commit']['id'], 'success')

  exitcode = $?.to_i

  Dir.chdir "../../../"

  exitcode
end

def render_view(view)
  erb "#{view}.#{@file_type}".to_sym
end

not_found do
  status 404
end
