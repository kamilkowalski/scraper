require_relative "./preprocessor"

module Scraper
  class Worker
    include Preprocessor

    def initialize(master, logger, config = nil)
      @master = master
      @pid = Process.pid
      @running = false
      @logger = logger
      @config = config

      setup_db
      prepare_queries
    end

    def run
      @running = true

      Signal.trap "SIGINT", "IGNORE"
      Signal.trap "SIGTERM" do
        @running = false
      end

      @logger.log "Starting worker...", pid: @pid, master: @master

      while(@running) do
        result = @db.exec_prepared("art_sel")
        result.each do |row|
          scrape(row["link"])
        end
      end

      @logger.log "Stopping worker...", pid: @pid, master: @master
    end

    private

    def scrape(url)
      @logger.log "Scraping URL: #{url}", pid: @pid, master: @master

      @db.exec_prepared("art_lock", [url])

      doc = Nokogiri::HTML(open(url))

      lead_text = doc.xpath("//div[@id='lead']//text()")
      detail_text = doc.xpath("//div[@id='detail']//text()")

      content = clear_text(lead_text) + "\n" + clear_text(detail_text)
      content = "" if content.length < 50
      @db.exec_prepared("art_upd", [content, url])

      links = extract_links(doc.xpath("//a[@href]"))

      links.each do |l|
        # Check if link created
        result = @db.exec_prepared("art_find", [l])
        if result.getvalue(0, 0).to_i == 0
          @db.exec_prepared("art_ins", [l])
        end
      end
    rescue StandardError => e
      @logger.log e.to_s, pid: @pid, master: @master
    end

    def setup_db
      if @config.nil?
        @config = {}
      end

      database_config = {
        "host" => "localhost",
        "dbname" => "database",
        "user" => "postgres",
        "password" => "postgres"
      }

      unless @config["database"].nil?
        database_config.merge!(@config["database"])
      end

      @db = PG.connect(database_config)
    end

    def prepare_queries
      @db.prepare("art_find", "SELECT COUNT(*) FROM articles WHERE link = $1")
      @db.prepare("art_sel", "SELECT link FROM articles WHERE processed = 'f' LIMIT 1")
      @db.prepare("art_ins", "INSERT INTO articles (link, processed, content) VALUES ($1, 'f', '')")
      @db.prepare("art_lock", "UPDATE articles SET processed = 't' WHERE link=$1")
      @db.prepare("art_upd", "UPDATE articles SET processed = 't', content=$1 WHERE link=$2")
    end
  end
end
