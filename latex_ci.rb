require 'sinatra'
require 'json'
require 'git'
require 'octokit'

before do
  @gh_client ||= Octokit::Client.new(access_token: ENV['TOKEN'])
end

post '/build' do
  @payload = JSON.parse params[:payload]
  @repo = @payload['repository']
  event_type = request.env['HTTP_X_GITHUB_EVENT']

  @gh_client.create_status(@repo['full_name'], @payload['head_commit']['id'], 'pending')

  case event_type
  when 'push'
    pull_repo @repo
    build_repo @repo
  end
end

def pull_repo(repo)
  repo_dir = "builds/#{repo['name']}"
  repo_url = repo['url']

  if File.directory? repo_dir
    g = Git.open repo_dir
    g.pull
  else
    g = Git.clone repo_url, repo_dir
  end
end

def build_repo(repo)
  repo_dir = "builds/#{repo['name']}"

  Dir.chdir repo_dir
  system 'latexmk -c'

  log = system 'latexmk > log.txt'

  p "AAAAAAAAA: #{log}"
  @gh_client.create_status(@repo['full_name'], @payload['head_commit']['id'], 'success')
end
