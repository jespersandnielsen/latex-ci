require 'git'
require './command_runner'

class RepoBuilder
  def initialize(gh_client, arguments)
    @gh_client = gh_client

    @id = arguments["id"]
    @repo = arguments["repo"]
    @branch = arguments["branch"]
    @build_context = arguments["build_context"]
    @event_type = arguments["event_type"]
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
      exitcode = run_command "dotnet clean"
      exitcode = run_command "dotnet restore --packages packages" unless exitcode == 0
      exitcode = run_command "dotnet build -c Debug /warnaserror" unless exitcode == 0

      # Test
      exitcode = run_command "dotnet test test/Petra.Test/Petra.Test.csproj" unless exitcode == 0
      exitcode = run_command "dotnet test test/Petra.Api.Test/Petra.Api.Test.csproj" unless exitcode == 0
      exitcode = run_command "dotnet test test/Petra.Model.Test/Petra.Model.Test.csproj" unless exitcode == 0

      # Code coverage
      exitcode = run_command "./build.ps1 --codecoverage" unless exitcode == 0

      # publish coverage result
      exitcode = run_command "./build.ps1 --publish --branch #{@branch}" unless exitcode == 0
    end
  end

  def run_command(cmd)
    Dir.chdir @repo_dir do
      CommandRunner.new("dotnet clean").run
    end
  end
end
