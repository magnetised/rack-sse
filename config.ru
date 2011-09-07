require 'bundler/setup'
require 'rack/async'
require 'eventmachine'

class AsyncApp

  def initialize
    @lock = Mutex.new
    @count = 0
    @timer = nil
    @clients = []
  end
  def call(env)
    event_machine do
      @timer ||= EM.add_periodic_timer(3) do
        @count += 1
        active_clients = []
        @lock.synchronize do
          @clients.each do |client|
            unless client.instance_variable_get("@finished")
              active_clients.push(client)
              client << "data: Message #{@count}\n\n"
            end
          end

          @clients = active_clients
          puts "#{Time.now}: Message #{@count}; Clients: #{@clients.length}"
        end
      end
    end
    # body = env['async.body']

    body = env['async.body']
    @lock.synchronize do
      @clients << body
    end

    [200, {"Content-type" => "text/event-stream"}, body]
  end

  private
  def event_machine(&block)
    if EM.reactor_running?
      block.call
    else
      Thread.new {EM.run}
      EM.next_tick(block)
    end
  end
end


class IndexApp
  def call(env)
    [200, {"Content-type" => "text/html"}, [(<<-PAGE)]]
      <!DOCTYPE HTML>
      <html lang="en">
      <head>
        <meta charset="UTF-8">
        <title>ASYNC</title>
        <script type="text/javascript">
        var source = new EventSource('/messages');

        var showMessage = function(msg) {
          var out = document.getElementById('stream');
          var d = document.createElement('div')
          var b = document.createElement('strong')
          b.innerHTML = msg;
          d.innerHTML = (new Date) + " ";
          d.appendChild(b);
          out.appendChild(d);
        };

        source.addEventListener('message', function(e) {
          showMessage(e.data);
        }, false);

        source.addEventListener('open', function(e) {
          // Connection was opened.
        }, false);
        source.addEventListener('error', function(e) {
          if (e.eventPhase == EventSource.CLOSED) {
            // Connection was closed.
          }
        }, false);
        </script>
      </head>
      <body>

      <div id="stream">
      </div>
      </body>
      </html>
    PAGE
  end
end



app = Rack::Builder.new do

  map "/messages" do
    use Rack::Async
    run AsyncApp.new
  end

  map "/" do
    run IndexApp.new
  end
end

run app
