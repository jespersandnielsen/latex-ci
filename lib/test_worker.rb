require 'sidekiq'

class TestWorker
  include Sidekiq::Worker

  def perform(test)
    case test
    when "easy"
      puts "easy"
    when "hard"
      puts "hard"
    end
  end
end
