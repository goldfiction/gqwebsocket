//custom.js
function attachXterm(){
    var term = new Terminal();
    var webSocket = new WebSocket("wss://"+window.location.host); // Replace with your WebSocket endpoint
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
    term.open(document.getElementById('xterm-terminal'));
    //term.write('Hello from \x1B[1;3;31mxterm.js\x1B[0m $ ')
    //term.focus();
}

$(document).ready(async function () {
    attachXterm()
 });