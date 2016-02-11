module Scraper
  class Logger
    def initialize(stdout)
      @stdout = stdout
    end

    def log(str, pid: nil, master: nil)
      unless pid.nil? && master.nil?
        pids = [pid, master].compact.join(" @ ")
        str = "[#{pids}]: " + str
      end
      @stdout.write "#{str}\n"
    end
  end
end
