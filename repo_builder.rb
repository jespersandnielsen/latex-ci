require 'git'
require 'fileutils'
require './command_runner'

class RepoBuilder
  def initialize(gh_client, params)
    @gh_client = gh_client

    @id = params["id"]
    @repo = params["repo"]
    @branch = params["branch"]
    @build_context = params["build_context"]
    @event_type = params["event_type"]
    @dir = "builds/#{@repo['name']}/#{@id}-#{Time.now.getutc.to_i}"
  end

  def build
    @gh_client.create_status(@repo['full_name'], @id, :pending, options: { context: @build_context })

    case @event_type
    when 'push'
      pull_repo
      exitcode = build_repo
      delete_repo
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

    if File.directory? @dir
      g = Git.open @dir
      g.fetch
    else
      g = Git.clone repo_url, @dir
    end

    g.checkout @id
  end

  def build_repo
    exitcode = CommandRunner.run "dotnet clean", @dir
    exitcode = CommandRunner.run "dotnet restore --packages packages", @dir if exitcode == 0
    exitcode = CommandRunner.run "dotnet build -c Debug /warnaserror", @dir if exitcode == 0

    # Test
    exitcode = CommandRunner.run "dotnet test test/Petra.Test/Petra.Test.csproj", @dir if exitcode == 0
    exitcode = CommandRunner.run "dotnet test test/Petra.Api.Test/Petra.Api.Test.csproj", @dir if exitcode == 0
    # exitcode = CommandRunner.run "dotnet test test/Petra.Model.Test/Petra.Model.Test.csproj", @dir if exitcode == 0

    # Code coverage
    exitcode = CommandRunner.run "./build.ps1 --codecoverage", @dir unless exitcode == 0

    # publish coverage result
    exitcode = CommandRunner.run "./build.ps1 --publish --branch #{@branch}", @dir unless exitcode == 0

    exitcode
  end

  def delete_repo
    FileUtils.rm_r @dir
  end
end
