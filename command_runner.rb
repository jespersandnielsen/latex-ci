class CommandRunner
  def initialize(cmd)
    @cmd = cmd
  end

  def run
    system @cmd

    $?.to_i
  end
end
