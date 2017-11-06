require 'git'

class RepoBuilder
  def initialize(gh_client, params)
    @gh_client = gh_client

    @id = params["id"]
    @repo = params["repo"]
    @branch = params["branch"]
    @build_context = params["build_context"]
    @event_type = params["event_type"]
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
    repo_dir = "builds/#{@repo['name']}/#{@branch}"
    repo_url = @repo['url']

    if File.directory? repo_dir
      g = Git.open repo_dir
      g.pull
    else
      g = Git.clone repo_url, repo_dir
    end
  end

  def build_repo
    repo_dir = "builds/#{@repo['name']}/#{@branch}"

    Dir.chdir repo_dir

    system 'latexmk -c'
    system 'latexmk -interaction=nonstopmode -halt-on-error > log.txt'

    exitcode = $?.to_i

    Dir.chdir "../../../"

    exitcode
  end
end
