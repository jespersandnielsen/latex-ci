require 'sinatra'
require 'json'
require 'git'

get '/' do
  'Latex-CI'
end

post '/build' do
  payload = JSON.parse params[:payload]
  repo = payload['repository']
  branch = payload['ref'][/([^\/]+)$/]
  event_type = request.env['HTTP_X_GITHUB_EVENT']

  case event_type
  when 'push'
    pull_repo repo, branch
    exitcode = build_repo repo, branch
  end

  return
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

  exitcode = $?.to_i

  Dir.chdir "../../../"

  exitcode
end
