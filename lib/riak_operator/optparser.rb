module RiakOperator
  class Optparser
    def parse(argv)
      opts = {}
      opt = OptionParser.new{|opt|
        opt.banner = "Usage: #{$0} [options]"
        opt.separator "Options:"
        
        opts[:url] = "http://localhost:8098"
        opt.on("-u", "--url STR", "riak uri") {|s|
          opts[:url] = s
        }

        opts[:host] = "127.0.0.1"
        opt.on("-h", "--host STR", "riak host") {|s|
          opts[:host] = s
        }

        opts[:port] = 8098
        opt.on("-p", "--port STR", "riak http port") {|s|
          opts[:port] = s.to_i
        }

        opts[:ssl] = false
        opt.on("-s", "--ssl", "use ssl or not") {|s|
          opts[:ssl] = true
        }

        opts[:debug] = false
        opt.on("-d", "--debug", "debug mode") {|s|
          opts[:debug] = true
        }

      }.parse(argv)

      if opts[:host] and opts[:port]
        protocol = opts[:ssl] ? "https" : "http"
        opts[:url] = "#{protocol}://#{opts[:host]}:#{opts[:port]}"
        puts ">> #{opts[:url]} <<"
      end

      opts
    end

  end
end
