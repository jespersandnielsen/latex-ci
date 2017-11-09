require 'git'
require './command_runner'

class RepoBuilder
  def initialize(gh_client, params)
    @gh_client = gh_client

    @id = params["id"]
    @repo = params["repo"]
    @build_context = params["build_context"]
    @event_type = params["event_type"]
    @repo_dir = "builds/#{@repo['name']}"
  end

  def build
    @gh_client.create_status(@repo['full_name'], @id, :pending, options: { context: @build_context })

    case @event_type
    when 'push'
      pull_repo
      exitcode = build_repo
    end

    status = case exitcode
    when 0 then :success
    else :failure
    end

    @gh_client.create_status(@repo['full_name'], @id, status, options: { context: @build_context })
  end

private

  def pull_repo
    repo_url = @repo['url']

    if File.directory? @repo_dir
      g = Git.open @repo_dir
      g.pull
    else
      g = Git.clone repo_url, @repo_dir
    end

    g.checkout @id
  end

  def build_repo
    Dir.chdir @repo_dir do
      CommandRunner.new('latexmk -c').run
      CommandRunner.new('latexmk -interaction=nonstopmode -halt-on-error > log.txt').run
    end
  end
end
