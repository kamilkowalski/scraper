module Scraper
  module Preprocessor
    def clear_text(nodes)
      nodes.map do |n|
        n.content.gsub(/[\n\r]/, "").gsub(/\s+/, " ")
      end.reject do |c|
        c.nil? || c == " " || c == "" || c.length < 5
      end.join("\n")
    end

    def extract_links(nodes)
      nodes.map do |n|
        n.attribute("href").content
      end.select do |l|
        /https?\:\/\/[^\/]*onet/ =~ l
      end
    end
  end
end
