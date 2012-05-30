require 'multi_json'
require 'eventmachine'

class Source
  
  AsyncResponse = [ -1, { }, [ ] ].freeze
  
  DATASOURCE = File.join(File.dirname(__FILE__), "data.txt").freeze
  
  EventMachine.kqueue = true if EventMachine.kqueue?
  
  class DeferrableBody
    
    include EventMachine::Deferrable
    
    def call(chunks)
      chunks.each do |chunk|
        @callback.call(chunk)
      end
    end
    
    def each(&block)
      @callback = block
    end
  end
  
  module SourceWatcher 
    
    def body=(body)
      @body = body
    end
    
    def file_modified
      File.open(path).each_line do |line|
        @body.call([ "id: #{Time.now.to_i}\n\n" ])
        @body.call([ "data: #{MultiJson.encode(:line => line)}\n\n" ])
      end
      @body.succeed
    end
  end
  
  class << self
    def call(env)
      
      body = DeferrableBody.new
      
      headers = {
        'Content-Type'  => 'text/event-stream',
        'Cache-Control' => 'no-cache',
        'Connection'    => 'keep-alive'
      }
      
      EventMachine::next_tick { env['async.callback'].call([ 200, headers, body ]) }
      
      EventMachine.watch_file(DATASOURCE, SourceWatcher) do |handler|
        handler.body = body
      end
      
      AsyncResponse
    end
  end
end