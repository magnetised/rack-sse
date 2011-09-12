require 'bundler/setup'
require 'rack/async'
require 'eventmachine'

class AsyncApp

  def initialize
    @lock = Mutex.new
    @timer = nil
    @clients = []
  end

  def call(env)

    body = env['async.body']

    @lock.synchronize do
      @clients << body
    end

    body.errback do
      cleanup!(body)
    end

    [200, {"Content-type" => "text/event-stream"}, body]
  end

  def deliver(message)
    data = "data: #{message}\n\n"
    @clients.each do |client|
      client << data
    end
    puts "#{Time.now}: Message #{message.inspect}; Clients: #{@clients.length}"
  end

  private

  def cleanup!(connection)
    @lock.synchronize do
      @clients.delete(connection)
    end
  end

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
        var source;
        var reconnect = function() {
          source = new EventSource('/messages');
          source.addEventListener('message', function(e) {
            showMessage(e.data);
          }, false);

          source.addEventListener('open', function(e) {
            // Connection was opened.
          }, false);

          source.addEventListener('error', function(e) {
            console.log("Source Error", e)
            if (e.eventPhase == EventSource.CLOSED) {
              // Connection was closed.
            }
          }, false);
        };

        var showMessage = function(msg) {
          var out = document.getElementById('stream');
          var d = document.createElement('div')
          var b = document.createElement('strong')
          var now = new Date;
          b.innerHTML = msg;
          d.innerHTML = now.getHours() + ":" + now.getMinutes() + ":" +now.getSeconds() + "  ";
          d.appendChild(b);
          out.appendChild(d);
        };

        reconnect();
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

messenger = AsyncApp.new

console = Thread.new do
  sleep(2)
  loop do
    print "Enter message: "
    msg = gets.chomp
    messenger.deliver(msg)
  end
end

app = Rack::Builder.new do

  map "/messages" do
    use Rack::Async
    run messenger
  end

  map "/" do
    run IndexApp.new
  end
end

run app
