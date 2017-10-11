require 'sinatra'
require 'json'
require 'git'

repo = ''

get '/' do
  'Latex-CI'
end

post '/build' do
  payload = JSON.parse(params[:payload])
  event_type = request.env['HTTP_X_GITHUB_EVENT']

  case event_type
  when 'push'
    if File.directory?('project')
      g = Git.open('project')
      g.pull

      Dir.chdir 'project'
      system("latexmk -c")
      system("latexmk > log.txt")
    else
      g = Git.clone(repo, 'project')
    end
  end
end

get '/log' do
  File.read(File.join(File.dirname(__FILE__), 'project/log.txt'))
end
