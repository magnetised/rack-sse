require 'bundler/setup'
require 'sinatra'

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

$connections = []

class StreamApp < Sinatra::Base
  def connections
    $connections
  end

  get "/" do
    content_type  "text/event-stream"
    stream(:keep_open) { |out|
      connections << out
    }
  end

  post "/" do
    data = "data: #{params[:message]}\n\n"
    connections.each { |out| out << data }
    "sent '#{params[:message]}'\n"
  end
end

app = Rack::Builder.new do

  map "/messages" do
    run StreamApp.new
  end

  map "/" do
    run IndexApp.new
  end
end

run app
