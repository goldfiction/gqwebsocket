//custom.js

var term;
var fitAddon;

function attachXterm(ssl){
    term = new Terminal({
      fontFamily: '"Source Code Pro", "Courier New", monospace',
      fontSize: 14,
      encoding: 'utf-8',
      theme: {
        background: '#000',
        foreground: '#fc6f03', // Default font color
        cursor: '#ffffff',
        black: '#000000',
        red: '#ff0000'
      }
    });
    //Microsoft YaHei
    // Cascadia Mono
    // JetBrains MONO
    // Source Code Pro

    //term = new Terminal({
    //  fontFamily: '"Microsoft YaHei", "Courier New", monospace',
    //  fontSize: 14
    //});

    //term = new Terminal();
    fitAddon = new FitAddon.FitAddon();

    currentURL = window.location.href;
    if (currentURL.indexOf("https") != -1) {
        ssl = true;
    } else {
        ssl = false;
    }
    
    var webSocket;
    if(ssl)
        webSocket = new WebSocket("wss://" + window.location.host);
    else
        webSocket = new WebSocket("ws://" + window.location.host);
    
    webSocket.binaryType = 'arraybuffer';
    
    // Handle any other events (e.g., terminal resizing, socket closing)
    webSocket.addEventListener('close', () => {
        console.log('WebSocket connection closed');
    });

    webSocket.addEventListener('error', (error) => {
        console.error('WebSocket error:', error);
    });

    var attachAddon = new AttachAddon.AttachAddon(webSocket);
    term.loadAddon(attachAddon);
    term.loadAddon(fitAddon);
    term.open(document.getElementById('xterm-terminal'));
    //term.write('Hello from \x1B[1;3;31mxterm.js\x1B[0m $ ')
    term.focus();
    fitAddon.fit();

    this.send = function (message, callback) {
        this.waitForConnection(function () {
            webSocket.send(message);
            if (typeof callback !== 'undefined') {
            callback();
            }
        }, 1000);
    };

    this.waitForConnection = function (callback, interval) {
        if (webSocket.readyState === 1) {
            callback();
        } else {
            var that = this;
            // optional: implement backoff for interval here
            setTimeout(function () {
                that.waitForConnection(callback, interval);
            }, interval);
        }
    };

    var that=this;
        var myDiv = document.getElementById('terminalgroup');

    // 2. Create the observer instance
    resizeObserver = new ResizeObserver(entries => {
    for (const entry of entries) {
        // The entry object contains information about the size change
        const { width, height } = entry.contentRect;
        //console.log(`Div resized. New dimensions: Width: ${width}px, Height: ${height}px`);

        fitAddon.fit();
        that.send(JSON.stringify({
        type: 'resize',
        cols: term.cols,
        rows: term.rows
        }));
    }
    });

    resizeObserver.observe(myDiv);

    return term;
}


$(document).ready(async function () {
    attachXterm();
 });

