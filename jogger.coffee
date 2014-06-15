serialport = require "serialport"
{SerialPort} = serialport

port = "/dev/ttyACM1" # your 'Oko's port here
server = "http://192.168.1.30:3000"

oko = new SerialPort port, {
  baudrate: 9600,
  parser: serialport.parsers.readline "\n"
}

oko.on "data", (data) ->
  process.stdout.write data + "\n"

G = (g) ->
  process.stdout.write "sent: #{g} - "
  oko.write g + "\n"
  return g

require('zappajs') ->
  @configure =>
    @use require('connect-assets')()
    @use 'bodyParser', 'methodOverride', 'static'
  @configure
    development: ->
      @use errorHandler: { dumpExceptions: on, showStack: on }
    production: ->
      @use 'errorHandler', 'staticCache'

  # ShapeOko Routes
  @get '/a': ->
    G "G90"
    return "Absolutely!"
  @get '/i': ->
    G "G91"
    return "Incremental!"
  @get '/move/:x/:y': ->
    G "G1 X#{@params.x} Y#{@params.y}"
  @get '/feed/:feed': ->
    G "G1 F#{@params.feed}"
  @get '/G1/:feed/:axis/:direction': ->
    G "G1 F#{@params.feed} #{@params.axis} #{@params.direction}"

  @get '/': ->
    @render 'index',
      server: server

  @view index: ->
    doctype 5
    html ->
      head ->
        title "NodeOko"
        meta name: "viewport", content: "width=device-width, initial-scale=1, maximum-scale=1"
        script src: "http://ajax.googleapis.com/ajax/libs/jquery/1.9.0/jquery.min.js"
        script src: "https://cdn.rawgit.com/EightMedia/hammer.js/3ea4891aff20fe398950c40257a26f238d8cd77b/hammer.min.js"
        script src: "/script.js"
        link rel:'stylesheet', href:'/style.css'
        div id: 'jog'

  @coffee '/script.js': ->
    $ ->
      server = "http://192.168.1.30:3000"
      $.get "#{server}/i"
      $.get "#{server}/feed/5000"

      every = (period, callback) ->
        setInterval callback, period

      momentum =
        x: 0
        y: 0
        tick: ->
          console.log "x: ", momentum.x, " y: ", momentum.y
          momentum.x /= 2
          momentum.y /= 2
          if Math.abs(momentum.x) > 0.01 or Math.abs(momentum.y) > 0.01
            $.get "#{server}/move/#{momentum.x}/#{momentum.y}"

      every 200, momentum.tick

      Hammer(document.getElementById("jog"))
        .on "drag", (ev) ->
          momentum.x += (  ev.gesture.deltaX / 1 )
          momentum.y += ( -ev.gesture.deltaY / 1 )

  @with css:'stylus'

  @stylus '/style.css': '''
    html, body
      height 100%
      margin 0px
      padding 0px
    ul
      list-style none
      position absolute
      top 0px
      right 0px
    li
      font-size 30px
      float left
      padding 15px
    #jog
      background ghostWhite
      height 100%
      width 100%
  '''
