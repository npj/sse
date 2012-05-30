require 'rack'
require 'source'

class Server 
    
  PUBLIC = File.join(File.dirname(__FILE__), 'public').freeze
  
  class << self
    
    def create
      Rack::Builder.new do
        
        use Rack::ShowExceptions
        
        map '/' do
          run Proc.new { |env| Server.static!(env) }
        end
        
        map '/source' do
          run Source
        end
      end
    end
    
    def static!(env)
      e = env.dup
      e['PATH_INFO'] = "index.html" if e['PATH_INFO'] == "/"
      Rack::File.new(PUBLIC).call(e)
    end
  end
end