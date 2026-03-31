#index.js

http = require('http')
https = require('https')
os = require('os')
express = require('express')
bodyParser = require('body-parser')
basicAuth = require('express-basic-auth')
WebSocket = require('ws')
pty = require('node-pty')
path = require('path')
iconv = require('iconv-lite')
fs=require('fs')


#console.log os.platform()
shell="bash"
if os.platform()=="win32"
  shell="powershell.exe"#"powershell.exe"
console.log shell

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

wss.on 'connection',(ws)->
  ptyProcess = pty.spawn shell,[],
    name: 'xterm-color'
    cwd: process.env.HOME
    env:{ ...process.env, TERM: 'xterm-256color', LANG:'en_US.UTF-8', LC_ALL:'en_US.UTF-8'}
    encoding: null
    #cols: 80
    #rows: 24

  console.log "Client connected. PID: "+ptyProcess.pid

  ptyProcess.on 'data',(data)->
    #buffer = Buffer.from data,'binary'
    #utf8String = iconv.decode buffer,'UTF-8'
    #utf8String = iconv.decode data,'GB2312'
    #ws.send utf8String
    ws.send data

  ws.on 'message',(message)->
    #console.log message.toString()
    try
      message=message.toString()
      if message.trim().startsWith("{")
        data=JSON.parse message
        if data.type=='resize'
          ptyProcess.resize data.cols,data.rows
          return
    catch e
      #console.log e
    ptyProcess.write message

  ws.on 'close',()->
    ptyProcess.kill()
    console.log "Client disconnected. Killed PID: "+ptyProcess.pid

console.log 'wss listening on port 6443'

server.listen 4080,'0.0.0.0',()->
  console.log 'http server lstening on port 4080'
sslserver.listen 6443,'0.0.0.0',()->
  console.log 'ssl server listening on port 6443'
