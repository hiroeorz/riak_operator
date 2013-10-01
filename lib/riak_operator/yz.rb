require "httpclient"
require "json"
require "yaml"
require "riak_operator/riak_client"

module RiakOperator
  class Yz
    attr_accessor :base_url, :debug
    attr_reader :content
    attr_reader :riak_client

    DEFAULT_SEARCH_OPTIONS = {:q => "*:*", :rows => 100}
    RESERVED_KEYWORD = [:wt, :sort, :fq, :fl, :facet, :rows, :q, :start, 
                        :group, :"group.field"]

    def initialize(riak_client)
      @riak_client = riak_client
      @base_url = @riak_client.base_url
      @debug = @riak_client.debug
      @yz_obj = nil
      @content = nil
    end

    def search(index_name, query_options)
      query = if query_options.kind_of? String
                query_options
              else
                parse_query_options(query_options)
              end

      puts query if @debug
      query_url = "#{@base_url}/search/#{index_name}/?wt=json&#{query}"
      encoded_url = URI.escape(query_url)
      YzObject.new(@base_url, 
                   @riak_client.http_client.get_content(encoded_url))
    end

    private

    def get_search_words(query_options)
      search_words = query_options.dup
      
      RESERVED_KEYWORD.each do |keyword|
        search_words.delete(keyword)
      end

      search_words
    end

    def parse_query_options(query_options)
      unless query_options.has_key?(:q)
        search_words = get_search_words(query_options)
        search_words.each {|key, val| query_options.delete(key)}

        unless search_words.empty?
          words_array = []
          
          search_words.each do |key, val|
            words_array.push("#{key}:#{val}")
          end
          
          query_options[:q] = words_array.join(" AND ")
        end
      end

      array = []

      default_options = DEFAULT_SEARCH_OPTIONS.dup
      query_options2 = default_options.merge(query_options)

      query_options2.each do |key, val|
        array.push("#{key}=#{val}")
      end

      array.join("&")
    end

  end
end
