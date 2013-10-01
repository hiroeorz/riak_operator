require "riak_operator/version"
require "httpclient"
require "json"

module RiakOperator
  class YzObject
    attr_reader :keys, :num_found

    def initialize(url, json, debug = false)
      @base_url = url
      @debug = debug
      hash = JSON.parse(json)
      @response_header = hash["responseHeader"]
      @response = hash["response"]
      @num_found = @response["numFound"]
      @docs = @response["docs"]

      @keys = @docs.map {|obj| 
        {:bucket => obj["_yz_rb"], :key => obj["_yz_rk"]}
      }
    end

    def get_all_keys_objects
      http_client = client
      result = {}

      @keys.each do |obj| 
        riak_obj = get_object(http_client, obj[:bucket], obj[:key])
        header = riak_obj[:header]
        bucket = header[:bucket]
        key = header[:key]
        content = riak_obj[:content]

        result[bucket] = [] unless result.has_key? bucket
        result[bucket].push [key, content]
      end

      result
    end

    private

    def get_object(client, bucket, key)
      query_url = "#{@base_url}/buckets/#{bucket}/keys/#{key}"
      content = JSON.parse client.get_content(query_url)
      {:header => {:bucket => bucket, :key => key}, :content => content}
    end

    def client
      http_client = HTTPClient.new
      http_client.ssl_config.verify_mode = OpenSSL::SSL::VERIFY_NONE
      http_client
    end
  end

end
