class CommandRunner
  def self.run(cmd, dir)
    Dir.chdir dir do
      system cmd
    end

    $?.to_i
  end
end
