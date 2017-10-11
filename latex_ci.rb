require 'sinatra'
require 'json'
require 'git'

get '/' do
  'Latex-CI'
end

post '/build' do
  payload = JSON.parse(params[:payload])
  event_type = request.env['HTTP_X_GITHUB_EVENT']

  case event_type
  when 'push'
    pull_repo(payload['repository'])
  end
end

def pull_repo(repo)
  repo_name = "builds/#{repo['name']}"
  repo_url = repo['url']

  if File.directory? repo_name
    g = Git.open repo_name
    g.pull

    Dir.chdir repo_name
    system 'latexmk -c'
    system "latexmk > log.txt"
  else
    g = Git.clone repo_url, repo_name
  end
end

get '/log' do
  File.read(File.join(File.dirname(__FILE__), 'project/log.txt'))
end
