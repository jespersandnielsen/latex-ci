require 'open3'
require 'sidekiq/api'

Sidekiq::Queue.new.clear

class CommandRunner
  def self.run(cmd, dir)

    # Dir.chdir dir do
    #   system cmd
      # IO.popen(cmd, chdir: dir)
    # end
    #
    Open3.popen3(cmd, chdir: dir) do |i,o,e,t|
      puts o.read
    end

    $?.to_i
  end
end
