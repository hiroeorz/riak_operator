require "httpclient"
require "json"

require "riak_operator/optparser"

module RiakOperator
  class RiakClient
    attr_accessor :bucket
    attr_reader :base_url, :debug

    HTTP_CODE_OK = 200
    HTTP_CODE_NOTFOUND = 404
    HTTP_CODE_NOCONTENT = 204
    
    def initialize
      @debug = false
      @base_url = nil
      @yz = nil
      @buckets = []
    end
    
    ### index and props handler

    def create_index(bucket)
      url = index_create_url(bucket)
      http_client.put(url, "", "content-type" => "application/json")
      set_index(bucket)
    end

    def props(bucket)
      url = props_url(bucket)
      response = http_client.get(url)

      if response.code == HTTP_CODE_NOTFOUND #only raised notfound_ok is true
        raise BucketNotFoundError.new("bucket:#{bucket}")
      end

      JSON.parse(response.body)
    end

    def set_props(bucket, props)
      url = props_url(bucket)
      parameter = {:props => props}.to_json
      http_client.put(url, parameter,
                      "content-type" => "application/json")
      true
    end

    ### object handler

    def find(bucket, key_or_options = {})
      if key_or_options.kind_of?(Hash)
        if key_or_options.has_key?(:_id)
          key = key_or_options[:_id]
          fake_list_return(bucket, key.to_s, find_one_by_key(bucket, key))
        else
          find_by_yokozuna(bucket, key_or_options)
        end
      else
        key = key_or_options
        fake_list_return(bucket, key.to_s, find_one_by_key(bucket, key))
      end
    end

    def find_one(bucket, key_or_options = {})
      result = if key_or_options.kind_of?(Hash)
                 find(bucket, key_or_options.merge(:rows => 1))
               else
                 find(bucket, key_or_options)
               end

      return nil if result.empty?
      result[0]
    end

    def find_one_by_key(bucket, key)
      response = http_client.get(url(bucket, key))

      if response.code == HTTP_CODE_NOTFOUND
        raise ObjectNotFoundError.new("bucket:#{bucket}, key:#{key}")
      end

      JSON.parse(response.body)
    end

    def update(bucket, query_options)
      raise "set parameter must include." unless query_options.has_key?(:set)
      update_vals = query_options[:set]

      if query_options.has_key?(:_id)
        key = query_options[:_id]
        update_one(bucket, key, update_vals)
      else
        update_by_search(bucket, query_options, update_vals)
      end
    end

    def insert(bucket, key_or_obj, obj_or_nil = nil)
      if obj_or_nil.nil? # key not defined
        key = nil
        obj = key_or_obj
      else               # key defined by user
        key = key_or_obj
        obj = obj_or_nil
      end

      http_client.post(url(bucket, key), obj.to_json, 
                       "content-type" => "application/json")
      true
    end

    def delete(bucket, key)
      response = http_client.delete(url(bucket, key))
      response.code == HTTP_CODE_NOCONTENT
    end

    def delete_field(bucket, field, query_options = {})
      result = find(bucket, query_options)

      result.each do |key_and_obj|
        key = key_and_obj[0]
        response = http_client.get(url(bucket, key))        
        next if response.code == HTTP_CODE_NOTFOUND
        vclock = response.header["X-Riak-Vclock"][0]

        obj = JSON.parse(response.body)
        obj.delete(field.to_s)
        update_obj(bucket, key, obj, vclock)
      end

      true
    end

    def buckets
      return @buckets unless @buckets.empty?

      query_url = "#{@base_url}/buckets?buckets=true"
      result = JSON.parse(http_client.get_content(query_url))
      @buckets = result["buckets"].sort
    end

    ### used by other class

    def set_command_line_options(argv)
      opt_parser = RiakOperator::Optparser.new
      opts = opt_parser.parse(argv)
      @base_url = opts[:url]
      @debug = opts[:debug]

      @yz = RiakOperator::Yz.new(self)
      @yz.base_url = @base_url
      @yz.debug = @debug
    end

    def http_client
      @http_client ||= HTTPClient.new

      if @http_client.ssl_config.verify_mode != OpenSSL::SSL::VERIFY_NONE
        @http_client.ssl_config.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end

      @http_client
    end

    private

    def url(bucket, key)
      "#{@base_url}/buckets/#{bucket}/keys/#{key}"
    end

    def index_create_url(bucket)
      index = "#{bucket}_index"
      "#{@base_url}/yz/index/#{index}"
    end

    def props_url(bucket)
      "#{@base_url}/buckets/#{bucket}/props"
    end

    def set_index(bucket)
      set_props(bucket, :yz_index => "#{bucket}_index")
    end

    def find_by_yokozuna(bucket, query_options = {})
      index = "#{bucket}_index"
      yz_obj = @yz.search(index, query_options)
      result = yz_obj.get_all_keys_objects

      if result.has_key?(bucket)
        []
      else
        result[bucket.to_s]
      end
    end

    def fake_list_return(bucket, key, value)
      [[key, value]]
    end

    def update_by_search(bucket, query_options, update_vals)
      index = "#{bucket}_index"
      query_options.delete(:set)
      result = find(bucket, query_options)

      result.each do |key_and_obj|
        key = key_and_obj[0]
        obj = key_and_obj[1]
        update_one(bucket, key, obj.merge(update_vals))
      end

      true
    end

    def update_obj(bucket, key, obj, vclock)
      http_client.put(url(bucket, key), obj.to_json, 
                      "content-type" => "application/json",
                      "X-Riak-Vclock" => vclock)
      true
    end

    def update_one(bucket, key, update_vals)
      response = http_client.get(url(bucket, key))        
      return false if response.code == HTTP_CODE_NOTFOUND

      vclock = response.header["X-Riak-Vclock"][0]
      obj = JSON.parse(response.body)
      new_obj = obj.merge(update_vals)
      update_obj(bucket, key, new_obj, vclock)
    end

  end

  class BucketNotFoundError < StandardError
  end

  class ObjectNotFoundError < StandardError
  end

end
