require 'sinatra'
require 'json'

get '/' do
  'Latex-CI'
end

post '/build' do
  payload = JSON.parse(params[:payload])
  event_type = request.env['HTTP_X_GITHUB_EVENT']

  case event_type
  when 'push'
    payload
  end
end
