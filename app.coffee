#index.js

http = require 'http'
https = require 'https'
os = require 'os'
express = require 'express'
bodyParser = require 'body-parser'
basicAuth = require 'express-basic-auth'
WebSocket = require 'ws'
pty = require 'node-pty'
path = require 'path'
iconv = require 'iconv-lite'
fs=require 'fs'
l=console.log


l os.platform()
shell="bash"
if os.platform()=="win32"
  shell="powershell.exe"#"powershell.exe"
l shell

options=
    key: fs.readFileSync('./private/key.pem'),
    cert: fs.readFileSync('./private/cert.pem')

app = express()

app.use basicAuth
  users: { admin: 'admin' }
  challenge: true

app.use bodyParser.json()
app.use bodyParser.urlencoded({ extended: true })
app.use express.static('public/www')

server=http.createServer options,app
sslserver = https.createServer options,app

wss = new WebSocket.Server
  server:sslserver

wss2 = new WebSocket.Server
  server:server

startwss=(wss)->
  wss.on 'connection',(ws)->
    ptyProcess = pty.spawn shell,[],
      name: 'xterm'
      cwd: process.env.HOME
      env:{ ...process.env, TERM: 'xterm', LANG:'en_US.UTF-8', LC_ALL:'en_US.UTF-8'}
      #env:{ ...process.env, TERM: 'xterm-256color', LANG:'en_US.UTF-8', LC_ALL:'en_US.UTF-8'}
      # encoding: null
      # cols: 80
      # rows: 24

    ws.isAlive = true
    #// Reset flag on pong response
    
    ws.on 'pong',()->
      ws.isAlive=true

    interval=setInterval ()->
      wss.clients.forEach (ws)->
        if ws.isAlive==false
          return ws.terminate() #// Terminate dead connection immediately
              
        ws.isAlive = false
        ws.ping() #// Send ping frame
    ,30000

    l "Client connected. PID: "+ptyProcess.pid

    ptyProcess.on 'data',(data)->
      #buffer = Buffer.from data,'binary'
      #utf8String = iconv.decode buffer,'UTF-8'
      #utf8String = iconv.decode data,'GB2312'
      #ws.send utf8String
      ws.send data

    ws.on 'message',(message)->
      #l message.toString()
      try
        message=message.toString()
        if message.trim().startsWith("{")
          data=JSON.parse message
          if data.type=='resize'
            ptyProcess.resize data.cols,data.rows
            return
      catch e
        #l e
      ptyProcess.write message

    ws.on 'close',()->
      ptyProcess.kill()
      clearInterval interval
      l "Client disconnected. Killed PID: "+ptyProcess.pid

  l 'wss listening'

startwss(wss)
startwss(wss2)

server.listen 4080,'0.0.0.0',()->
  l 'http server lstening on port 4080'
sslserver.listen 6443,'0.0.0.0',()->
  l 'ssl server listening on port 6443'
