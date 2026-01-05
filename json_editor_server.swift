#!/usr/bin/env swift

import Foundation

// Simple HTTP server for editing employees.json
class JSONEditorServer {
    let port: UInt16
    let jsonFilePath: String
    var server: HTTPServer?
    
    init(port: UInt16 = 8080, jsonFilePath: String) {
        self.port = port
        self.jsonFilePath = jsonFilePath
    }
    
    func start() {
        let server = HTTPServer(port: port)
        self.server = server
        
        // Serve the HTML editor page
        server.get("/") { request, response in
            response.statusCode = 200
            response.setHeader("Content-Type", value: "text/html")
            response.body = self.getHTMLPage()
        }
        
        // Get JSON
        server.get("/api/employees") { request, response in
            response.statusCode = 200
            response.setHeader("Content-Type", value: "application/json")
            response.setHeader("Access-Control-Allow-Origin", value: "*")
            response.body = self.loadJSON()
        }
        
        // Save JSON
        server.post("/api/employees") { request, response in
            if let body = request.body, let jsonString = String(data: body, encoding: .utf8) {
                if self.saveJSON(jsonString) {
                    response.statusCode = 200
                    response.setHeader("Content-Type", value: "application/json")
                    response.setHeader("Access-Control-Allow-Origin", value: "*")
                    response.body = "{\"success\": true}".data(using: .utf8)
                } else {
                    response.statusCode = 500
                    response.body = "{\"success\": false, \"error\": \"Failed to save\"}".data(using: .utf8)
                }
            } else {
                response.statusCode = 400
                response.body = "{\"success\": false, \"error\": \"Invalid request\"}".data(using: .utf8)
            }
        }
        
        server.start()
        print("JSON Editor Server running on http://localhost:\(port)")
        print("Press Ctrl+C to stop")
    }
    
    func loadJSON() -> Data? {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: jsonFilePath)) else {
            return "[]".data(using: .utf8)
        }
        return data
    }
    
    func saveJSON(_ jsonString: String) -> Bool {
        // Validate JSON first
        guard let data = jsonString.data(using: .utf8),
              let _ = try? JSONSerialization.jsonObject(with: data) else {
            return false
        }
        
        // Create backup
        let backupPath = jsonFilePath + ".backup"
        if FileManager.default.fileExists(atPath: jsonFilePath) {
            try? FileManager.default.copyItem(atPath: jsonFilePath, toPath: backupPath)
        }
        
        // Save new JSON
        do {
            try jsonString.write(toFile: jsonFilePath, atomically: true, encoding: .utf8)
            return true
        } catch {
            print("Error saving JSON: \(error)")
            return false
        }
    }
    
    func getHTMLPage() -> Data {
        let html = """
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Employee JSON Editor</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
            background: #f5f5f5;
            padding: 20px;
        }
        .container {
            max-width: 1200px;
            margin: 0 auto;
            background: white;
            border-radius: 8px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            padding: 30px;
        }
        h1 {
            color: #333;
            margin-bottom: 10px;
        }
        .subtitle {
            color: #666;
            margin-bottom: 30px;
        }
        .toolbar {
            display: flex;
            gap: 10px;
            margin-bottom: 20px;
            flex-wrap: wrap;
        }
        button {
            padding: 10px 20px;
            border: none;
            border-radius: 6px;
            cursor: pointer;
            font-size: 14px;
            font-weight: 500;
            transition: all 0.2s;
        }
        button:hover {
            transform: translateY(-1px);
            box-shadow: 0 2px 5px rgba(0,0,0,0.2);
        }
        .btn-primary {
            background: #007AFF;
            color: white;
        }
        .btn-secondary {
            background: #6c757d;
            color: white;
        }
        .btn-success {
            background: #28a745;
            color: white;
        }
        .btn-danger {
            background: #dc3545;
            color: white;
        }
        #editor {
            width: 100%;
            min-height: 500px;
            font-family: 'Monaco', 'Menlo', 'Courier New', monospace;
            font-size: 14px;
            padding: 15px;
            border: 2px solid #ddd;
            border-radius: 6px;
            resize: vertical;
            tab-size: 2;
        }
        #editor:focus {
            outline: none;
            border-color: #007AFF;
        }
        .status {
            margin-top: 15px;
            padding: 10px;
            border-radius: 6px;
            display: none;
        }
        .status.success {
            background: #d4edda;
            color: #155724;
            border: 1px solid #c3e6cb;
        }
        .status.error {
            background: #f8d7da;
            color: #721c24;
            border: 1px solid #f5c6cb;
        }
        .status.info {
            background: #d1ecf1;
            color: #0c5460;
            border: 1px solid #bee5eb;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>Employee JSON Editor</h1>
        <p class="subtitle">Edit the employees.json file for development purposes</p>
        
        <div class="toolbar">
            <button class="btn-primary" onclick="loadJSON()">Load JSON</button>
            <button class="btn-success" onclick="saveJSON()">Save JSON</button>
            <button class="btn-secondary" onclick="formatJSON()">Format JSON</button>
            <button class="btn-danger" onclick="validateJSON()">Validate JSON</button>
        </div>
        
        <textarea id="editor" placeholder="Click 'Load JSON' to load the current employees.json file..."></textarea>
        
        <div id="status" class="status"></div>
    </div>
    
    <script>
        let originalJSON = '';
        
        async function loadJSON() {
            try {
                showStatus('Loading JSON...', 'info');
                const response = await fetch('/api/employees');
                if (!response.ok) throw new Error('Failed to load JSON');
                const json = await response.json();
                originalJSON = JSON.stringify(json, null, 2);
                document.getElementById('editor').value = originalJSON;
                showStatus('JSON loaded successfully!', 'success');
            } catch (error) {
                showStatus('Error loading JSON: ' + error.message, 'error');
            }
        }
        
        async function saveJSON() {
            const editor = document.getElementById('editor');
            const jsonText = editor.value.trim();
            
            if (!jsonText) {
                showStatus('JSON is empty!', 'error');
                return;
            }
            
            // Validate JSON
            try {
                JSON.parse(jsonText);
            } catch (error) {
                showStatus('Invalid JSON: ' + error.message, 'error');
                return;
            }
            
            try {
                showStatus('Saving JSON...', 'info');
                const response = await fetch('/api/employees', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json'
                    },
                    body: jsonText
                });
                
                if (!response.ok) {
                    const error = await response.json();
                    throw new Error(error.error || 'Failed to save');
                }
                
                originalJSON = jsonText;
                showStatus('JSON saved successfully!', 'success');
            } catch (error) {
                showStatus('Error saving JSON: ' + error.message, 'error');
            }
        }
        
        function formatJSON() {
            const editor = document.getElementById('editor');
            try {
                const json = JSON.parse(editor.value);
                editor.value = JSON.stringify(json, null, 2);
                showStatus('JSON formatted!', 'success');
            } catch (error) {
                showStatus('Invalid JSON: ' + error.message, 'error');
            }
        }
        
        function validateJSON() {
            const editor = document.getElementById('editor');
            try {
                JSON.parse(editor.value);
                showStatus('JSON is valid!', 'success');
            } catch (error) {
                showStatus('Invalid JSON: ' + error.message, 'error');
            }
        }
        
        function showStatus(message, type) {
            const status = document.getElementById('status');
            status.textContent = message;
            status.className = 'status ' + type;
            status.style.display = 'block';
            setTimeout(() => {
                status.style.display = 'none';
            }, 5000);
        }
        
        // Auto-load on page load
        window.addEventListener('load', () => {
            loadJSON();
        });
    </script>
</body>
</html>
"""
        return html.data(using: .utf8)!
    }
}

// Simple HTTP Server Implementation
class HTTPServer {
    let port: UInt16
    var routes: [String: (HTTPRequest, HTTPResponse) -> Void] = [:]
    
    init(port: UInt16) {
        self.port = port
    }
    
    func get(_ path: String, handler: @escaping (HTTPRequest, HTTPResponse) -> Void) {
        routes["GET \(path)"] = handler
    }
    
    func post(_ path: String, handler: @escaping (HTTPRequest, HTTPResponse) -> Void) {
        routes["POST \(path)"] = handler
    }
    
    func start() {
        let socket = Socket()
        socket.bind(port: port)
        socket.listen()
        
        DispatchQueue.global().async {
            while true {
                if let client = socket.accept() {
                    DispatchQueue.global().async {
                        self.handleClient(client)
                    }
                }
            }
        }
        
        // Keep the server running
        RunLoop.main.run()
    }
    
    func handleClient(_ client: Socket) {
        defer { client.close() }
        
        guard let request = HTTPRequest(from: client) else { return }
        let response = HTTPResponse()
        
        let routeKey = "\(request.method) \(request.path)"
        if let handler = routes[routeKey] {
            handler(request, response)
        } else {
            response.statusCode = 404
            response.body = "Not Found".data(using: .utf8)
        }
        
        client.send(response.toData())
    }
}

// Simple Socket Implementation
class Socket {
    var socketFD: Int32 = -1
    
    func bind(port: UInt16) {
        socketFD = Darwin.socket(AF_INET, SOCK_STREAM, 0)
        var reuse: Int32 = 1
        setsockopt(socketFD, SOL_SOCKET, SO_REUSEADDR, &reuse, socklen_t(MemoryLayout<Int32>.size))
        
        var addr = sockaddr_in()
        addr.sin_family = sa_family_t(AF_INET)
        addr.sin_port = port.bigEndian
        addr.sin_addr.s_addr = INADDR_ANY.bigEndian
        
        withUnsafePointer(to: &addr) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                _ = Darwin.bind(socketFD, $0, socklen_t(MemoryLayout<sockaddr_in>.size))
            }
        }
    }
    
    func listen() {
        Darwin.listen(socketFD, 5)
    }
    
    func accept() -> Socket? {
        var addr = sockaddr_in()
        var len = socklen_t(MemoryLayout<sockaddr_in>.size)
        
        let clientFD = withUnsafeMutablePointer(to: &addr) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                Darwin.accept(socketFD, $0, &len)
            }
        }
        
        guard clientFD >= 0 else { return nil }
        
        let client = Socket()
        client.socketFD = clientFD
        return client
    }
    
    func receive() -> Data? {
        var buffer = [UInt8](repeating: 0, count: 4096)
        let bytesRead = Darwin.recv(socketFD, &buffer, buffer.count, 0)
        guard bytesRead > 0 else { return nil }
        return Data(buffer[0..<bytesRead])
    }
    
    func send(_ data: Data) {
        _ = data.withUnsafeBytes { bytes in
            Darwin.send(socketFD, bytes.baseAddress, data.count, 0)
        }
    }
    
    func close() {
        if socketFD >= 0 {
            Darwin.close(socketFD)
            socketFD = -1
        }
    }
}

// HTTP Request
struct HTTPRequest {
    let method: String
    let path: String
    let headers: [String: String]
    let body: Data?
    
    init?(from socket: Socket) {
        guard let data = socket.receive(),
              let requestString = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        let lines = requestString.components(separatedBy: "\r\n")
        guard let firstLine = lines.first else { return nil }
        
        let components = firstLine.components(separatedBy: " ")
        guard components.count >= 3 else { return nil }
        
        method = components[0]
        path = components[1]
        
        var headers: [String: String] = [:]
        var bodyStartIndex = 1
        for (index, line) in lines.enumerated() {
            if line.isEmpty {
                bodyStartIndex = index + 1
                break
            }
            if index > 0 {
                let parts = line.components(separatedBy: ": ")
                if parts.count == 2 {
                    headers[parts[0].lowercased()] = parts[1]
                }
            }
        }
        self.headers = headers
        
        if bodyStartIndex < lines.count {
            let bodyString = lines[bodyStartIndex...].joined(separator: "\r\n")
            body = bodyString.data(using: .utf8)
        } else {
            body = nil
        }
    }
}

// HTTP Response
class HTTPResponse {
    var statusCode: Int = 200
    var headers: [String: String] = [:]
    var body: Data?
    
    func setHeader(_ name: String, value: String) {
        headers[name] = value
    }
    
    func toData() -> Data {
        var response = "HTTP/1.1 \(statusCode) \(statusText)\r\n"
        
        if !headers.keys.contains("content-length") {
            let length = body?.count ?? 0
            response += "Content-Length: \(length)\r\n"
        }
        
        for (key, value) in headers {
            response += "\(key): \(value)\r\n"
        }
        
        response += "\r\n"
        
        var data = response.data(using: .utf8)!
        if let body = body {
            data.append(body)
        }
        
        return data
    }
    
    var statusText: String {
        switch statusCode {
        case 200: return "OK"
        case 400: return "Bad Request"
        case 404: return "Not Found"
        case 500: return "Internal Server Error"
        default: return "Unknown"
        }
    }
}

// Main
let args = CommandLine.arguments
let jsonPath: String
let port: UInt16

if args.count > 1 {
    jsonPath = args[1]
} else {
    // Default path - adjust to your Documents directory
    let home = FileManager.default.homeDirectoryForCurrentUser
    jsonPath = home.appendingPathComponent("Documents/employees.json").path
}

if args.count > 2, let p = UInt16(args[2]) {
    port = p
} else {
    port = 8080
}

print("Starting JSON Editor Server...")
print("JSON File: \(jsonPath)")
print("Port: \(port)")

let server = JSONEditorServer(port: port, jsonFilePath: jsonPath)
server.start()

