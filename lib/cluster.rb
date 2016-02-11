module Scraper
  class Cluster
    def initialize(options = {})
      @options = defaults.merge(options)
      @workers = []
      @logger = Logger.new(STDOUT)
      @config = load_config
    end

    def start
      count = @options[:workers] - @workers.size
      master = Process.pid

      count.times do
        pid = fork { worker(master) }
        puts "Spawned worker #{pid}"
        @workers << pid
      end


      Signal.trap "TERM" do
        stop_workers
      end

      Signal.trap "INT" do
        stop_workers
      end

      Process.waitall
    end

    private

    def stop_workers
      puts "Stopping workers"
      @workers.each do |pid|
        Process.kill "TERM", pid
      end

      begin
        Process.waitall
      rescue Interrupt
        puts "Interrupted stopping process"
      end
    end

    def worker(master)
      Worker.new(master, @logger, @config).run
    rescue Interrupt
      puts "Cluster worker interrupted"
    end

    def load_config
      @config = {}
      unless @options[:config].nil?
        if File.exist?(@options[:config])
          @config = YAML.load_file(@options[:config])
        end
      end
    end

    def defaults
      {
        workers: 5
      }
    end
  end
end
