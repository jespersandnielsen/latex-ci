class CommandRunner
  def self.run(cmd, dir)
    exitcode = -1

    Dir.chdir dir do
      system cmd

      exitcode = $?.to_i
    end

    exitcode
  end
end
