#index.js

https = require('https')
express = require('express')
bodyParser = require('body-parser')
basicAuth = require('express-basic-auth')
WebSocket = require('ws')
pty = require('node-pty')
path = require('path')

fs=require('fs')

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

sslserver = https.createServer options,app

wss = new WebSocket.Server
  server:sslserver

wss.on 'connection',(ws)->
  ptyProcess = pty.spawn 'bash',[],
    name: 'xterm-color',
    cols: 80,
    rows: 24,
    cwd: process.env.HOME,
    env: process.env

  console.log "Client connected. PID: "+ptyProcess.pid

  ptyProcess.on 'data',(data)->
    ws.send data

  ws.on 'message',(message)->
    ptyProcess.write message

  ws.on 'close',()->
    ptyProcess.kill()
    console.log "Client disconnected. Killed PID: "+ptyProcess.pid

console.log 'wss listening on port 443'

sslserver.listen 443,()->
  console.log 'ssl server listening on port 443'
