Really simple server that generates events as per the HTML5 Server-Sent Events spec.

[http://dev.w3.org/html5/eventsource/](http://dev.w3.org/html5/eventsource/)

To try it out:

    $ git clone git://github.com/magnetised/rack-sse.git
    $ cd rack-sse
    $ bundle install
    $ bundle exec thin start

Then goto http://localhost:3000 in your browser or view the
message stream directly using `curl`:

    curl -v http://localhost:3000/messages

To send a message you have to send a POST to `/messages`. Using `curl`:

    curl -X POST -d "message=hello99s" http://localhost:3000/messages

This uses the [new `stream` method in Sinatra 1.3](http://www.sinatrarb.com/2011/09/30/sinatra-1.3.0) (and the evented connections
provided by Thin) to keep multiple connections open
without stressing the server.

