#!/usr/bin/env python3
"""
Simple HTTP server for editing employees.json file.
Usage: python3 json_editor_server.py [json_file_path] [port]
"""

import http.server
import socketserver
import json
import os
import sys
from urllib.parse import urlparse, parse_qs

# Default configuration
DEFAULT_PORT = 8080
DEFAULT_JSON_PATH = os.path.expanduser("~/Documents/employees.json")

class JSONEditorHandler(http.server.SimpleHTTPRequestHandler):
    json_file_path = DEFAULT_JSON_PATH
    
    def do_GET(self):
        if self.path == '/':
            self.send_response(200)
            self.send_header('Content-type', 'text/html')
            self.end_headers()
            html = self.get_html_page()
            # Replace the file path placeholder
            html = html.replace('{FILE_PATH}', self.json_file_path)
            self.wfile.write(html.encode())
        elif self.path == '/api/employees':
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.send_header('Access-Control-Allow-Origin', '*')
            self.end_headers()
            json_data = self.load_json()
            self.wfile.write(json_data.encode())
        elif self.path == '/api/apppath':
            # GET saved app path
            config_path = os.path.join(os.path.dirname(self.json_file_path), '.json_editor_config')
            app_path = ''
            if os.path.exists(config_path):
                try:
                    with open(config_path, 'r') as f:
                        app_path = f.read().strip()
                except:
                    pass
            
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.send_header('Access-Control-Allow-Origin', '*')
            self.end_headers()
            self.wfile.write(json.dumps({"appPath": app_path}).encode())
        else:
            self.send_response(404)
            self.end_headers()
    
    def do_POST(self):
        if self.path == '/api/employees':
            content_length = int(self.headers['Content-Length'])
            post_data = self.rfile.read(content_length)
            json_string = post_data.decode('utf-8')
            
            if self.save_json(json_string):
                self.send_response(200)
                self.send_header('Content-type', 'application/json')
                self.send_header('Access-Control-Allow-Origin', '*')
                self.end_headers()
                self.wfile.write(b'{"success": true}')
            else:
                self.send_response(500)
                self.send_header('Content-type', 'application/json')
                self.end_headers()
                self.wfile.write(b'{"success": false, "error": "Failed to save"}')
        elif self.path == '/api/export':
            content_length = int(self.headers['Content-Length'])
            post_data = self.rfile.read(content_length)
            data = json.loads(post_data.decode('utf-8'))
            app_path = data.get('appPath', '').strip()
            
            result = self.export_to_app(app_path)
            self.send_response(200 if result['success'] else 500)
            self.send_header('Content-type', 'application/json')
            self.send_header('Access-Control-Allow-Origin', '*')
            self.end_headers()
            self.wfile.write(json.dumps(result).encode())
        elif self.path == '/api/apppath':
            content_length = int(self.headers['Content-Length'])
            post_data = self.rfile.read(content_length)
            data = json.loads(post_data.decode('utf-8'))
            app_path = data.get('appPath', '').strip()
            
            # Save to a config file
            config_path = os.path.join(os.path.dirname(self.json_file_path), '.json_editor_config')
            try:
                # Ensure directory exists
                config_dir = os.path.dirname(config_path)
                if config_dir and not os.path.exists(config_dir):
                    os.makedirs(config_dir, exist_ok=True)
                
                with open(config_path, 'w') as f:
                    f.write(app_path)
                
                print(f"Saved app path to: {config_path}")  # Debug output
                self.send_response(200)
                self.send_header('Content-type', 'application/json')
                self.send_header('Access-Control-Allow-Origin', '*')
                self.end_headers()
                self.wfile.write(b'{"success": true}')
            except Exception as e:
                print(f"Error saving app path: {e}")  # Debug output
                self.send_response(500)
                self.send_header('Content-type', 'application/json')
                self.end_headers()
                self.wfile.write(json.dumps({"success": False, "error": str(e)}).encode())
        else:
            self.send_response(404)
            self.end_headers()
    
    def load_json(self):
        try:
            if os.path.exists(self.json_file_path):
                with open(self.json_file_path, 'r', encoding='utf-8') as f:
                    data = json.load(f)
                    return json.dumps(data, indent=2)
            else:
                # Return empty array if file doesn't exist
                return '[]'
        except json.JSONDecodeError as e:
            return json.dumps({"error": f"Invalid JSON: {str(e)}"})
        except Exception as e:
            return json.dumps({"error": str(e)})
    
    def save_json(self, json_string):
        try:
            # Validate JSON
            json.loads(json_string)
            
            # Create backup
            backup_path = self.json_file_path + '.backup'
            if os.path.exists(self.json_file_path):
                try:
                    import shutil
                    shutil.copy2(self.json_file_path, backup_path)
                except:
                    pass
            
            # Save JSON
            os.makedirs(os.path.dirname(self.json_file_path) if os.path.dirname(self.json_file_path) else '.', exist_ok=True)
            with open(self.json_file_path, 'w', encoding='utf-8') as f:
                f.write(json_string)
            
            return True
        except Exception as e:
            print(f"Error saving JSON: {e}")
            return False
    
    def export_to_app(self, app_path):
        """Export the JSON file to the iOS app's Documents directory"""
        try:
            if not app_path:
                return {"success": False, "error": "App path not specified"}
            
            # Expand user path
            app_path = os.path.expanduser(app_path)
            
            # Ensure it's a directory path, add employees.json if needed
            if os.path.isdir(app_path):
                target_path = os.path.join(app_path, 'employees.json')
            else:
                target_path = app_path
            
            # Read source file
            if not os.path.exists(self.json_file_path):
                return {"success": False, "error": "Source file does not exist"}
            
            # Copy file
            import shutil
            os.makedirs(os.path.dirname(target_path) if os.path.dirname(target_path) else '.', exist_ok=True)
            shutil.copy2(self.json_file_path, target_path)
            
            return {"success": True, "message": f"Exported to {target_path}"}
        except Exception as e:
            return {"success": False, "error": str(e)}
    
    def get_html_page(self):
        html_template = """<!DOCTYPE html>
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
        .file-info {
            background: #e9ecef;
            padding: 10px;
            border-radius: 6px;
            margin-bottom: 20px;
            font-family: monospace;
            font-size: 12px;
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
        button:disabled {
            opacity: 0.5;
            cursor: not-allowed;
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
        table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 20px;
        }
        th, td {
            padding: 12px;
            text-align: left;
            border-bottom: 1px solid #ddd;
        }
        th {
            background: #f8f9fa;
            font-weight: 600;
            color: #333;
        }
        tr:hover {
            background: #f8f9fa;
        }
        .action-buttons {
            display: flex;
            gap: 8px;
        }
        .btn-small {
            padding: 6px 12px;
            font-size: 12px;
        }
        .modal {
            display: none;
            position: fixed;
            z-index: 1000;
            left: 0;
            top: 0;
            width: 100%;
            height: 100%;
            background: rgba(0,0,0,0.5);
        }
        .modal-content {
            background: white;
            margin: 5% auto;
            padding: 0;
            border-radius: 8px;
            width: 90%;
            max-width: 500px;
            box-shadow: 0 4px 20px rgba(0,0,0,0.3);
        }
        .modal-header {
            padding: 20px;
            border-bottom: 1px solid #ddd;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        .modal-header h2 {
            margin: 0;
        }
        .close {
            font-size: 28px;
            font-weight: bold;
            color: #aaa;
            cursor: pointer;
        }
        .close:hover {
            color: #000;
        }
        .form-group {
            margin-bottom: 20px;
            padding: 0 20px;
        }
        .form-group label {
            display: block;
            margin-bottom: 5px;
            font-weight: 500;
            color: #333;
        }
        .form-group input,
        .form-group select {
            width: 100%;
            padding: 10px;
            border: 1px solid #ddd;
            border-radius: 4px;
            font-size: 14px;
        }
        .form-actions {
            padding: 20px;
            border-top: 1px solid #ddd;
            display: flex;
            justify-content: flex-end;
            gap: 10px;
        }
        .empty-state {
            text-align: center;
            padding: 40px;
            color: #666;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>Employee JSON Editor</h1>
        <p class="subtitle">Edit the employees.json file for development purposes</p>
        <div class="file-info" id="fileInfo">File: {FILE_PATH}</div>
        
        <div class="toolbar">
            <button class="btn-success" onclick="addEmployee()">+ Add Employee</button>
            <button class="btn-secondary" onclick="refreshList()">Refresh</button>
            <button class="btn-primary" onclick="exportToApp()">Export to App</button>
        </div>
        
        <div class="file-info" style="margin-top: 10px;">
            <strong>Export Settings:</strong><br>
            <input type="text" id="appPath" placeholder="iOS App Documents Path (e.g., ~/Library/Developer/CoreSimulator/...)" style="width: 70%; padding: 8px; margin-top: 5px;">
            <button class="btn-secondary" onclick="saveAppPath()" style="margin-left: 10px;">Save Path</button>
        </div>
        
        <div id="employeeTable"></div>
        
        <div id="status" class="status"></div>
        
        <!-- Edit Modal -->
        <div id="editModal" class="modal" style="display: none;">
            <div class="modal-content">
                <div class="modal-header">
                    <h2 id="modalTitle">Add Employee</h2>
                    <span class="close" onclick="closeModal()">&times;</span>
                </div>
                <form id="employeeForm" onsubmit="saveEmployee(event)">
                    <input type="hidden" id="employeeId" value="">
                    <div class="form-group">
                        <label>Name *</label>
                        <input type="text" id="employeeName" required>
                    </div>
                    <div class="form-group">
                        <label>Hired Year *</label>
                        <input type="number" id="employeeHiredYear" required>
                    </div>
                    <div class="form-group">
                        <label>Date of Birth (Year) *</label>
                        <input type="number" id="employeeDateOfBirth" required>
                    </div>
                    <div class="form-group">
                        <label>Sex *</label>
                        <select id="employeeSex" required>
                            <option value="M">Male</option>
                            <option value="F">Female</option>
                        </select>
                    </div>
                    <div class="form-group">
                        <label>Spouse Date of Birth (Year, 0 for none)</label>
                        <input type="number" id="employeeSpouseDateOfBirth" value="0">
                    </div>
                    <div class="form-group" id="spouseSexGroup" style="display: none;">
                        <label>Spouse Sex</label>
                        <select id="employeeSpouseSex">
                            <option value="M">Male</option>
                            <option value="F">Female</option>
                        </select>
                    </div>
                    <div class="form-actions">
                        <button type="button" class="btn-secondary" onclick="closeModal()">Cancel</button>
                        <button type="submit" class="btn-success">Save</button>
                    </div>
                </form>
            </div>
        </div>
    </div>
    
    <script>
        let employees = [];
        
        async function refreshList() {
            try {
                showStatus('Loading employees...', 'info');
                const response = await fetch('/api/employees');
                if (!response.ok) throw new Error('Failed to load employees');
                employees = await response.json();
                renderTable();
                showStatus('Employees loaded successfully!', 'success');
            } catch (error) {
                showStatus('Error loading employees: ' + error.message, 'error');
            }
        }
        
        function renderTable() {
            const tableDiv = document.getElementById('employeeTable');
            
            if (employees.length === 0) {
                tableDiv.innerHTML = '<div class="empty-state"><p>No employees found. Click "Add Employee" to get started.</p></div>';
                return;
            }
            
            let html = '<table><thead><tr><th>ID</th><th>Name</th><th>Hired Year</th><th>Date of Birth</th><th>Sex</th><th>Spouse DOB</th><th>Actions</th></tr></thead><tbody>';
            
            employees.forEach(emp => {
                html += `<tr>
                    <td>${emp.id || ''}</td>
                    <td>${emp.name || ''}</td>
                    <td>${emp.hiredYear || ''}</td>
                    <td>${emp.dateOfBirth || ''}</td>
                    <td>${emp.sex || ''}</td>
                    <td>${emp.spouseDateOfBirth > 0 ? emp.spouseDateOfBirth : 'None'}</td>
                    <td>
                        <div class="action-buttons">
                            <button class="btn-primary btn-small" onclick="editEmployee(${emp.id})">Edit</button>
                            <button class="btn-danger btn-small" onclick="deleteEmployee(${emp.id})">Delete</button>
                        </div>
                    </td>
                </tr>`;
            });
            
            html += '</tbody></table>';
            tableDiv.innerHTML = html;
        }
        
        function addEmployee() {
            document.getElementById('modalTitle').textContent = 'Add Employee';
            document.getElementById('employeeId').value = '';
            document.getElementById('employeeName').value = '';
            document.getElementById('employeeHiredYear').value = new Date().getFullYear();
            document.getElementById('employeeDateOfBirth').value = '';
            document.getElementById('employeeSex').value = 'M';
            document.getElementById('employeeSpouseDateOfBirth').value = '0';
            document.getElementById('employeeSpouseSex').value = 'F';
            document.getElementById('spouseSexGroup').style.display = 'none';
            document.getElementById('editModal').style.display = 'block';
        }
        
        function editEmployee(id) {
            const employee = employees.find(e => e.id === id);
            if (!employee) return;
            
            document.getElementById('modalTitle').textContent = 'Edit Employee';
            document.getElementById('employeeId').value = employee.id;
            document.getElementById('employeeName').value = employee.name || '';
            document.getElementById('employeeHiredYear').value = employee.hiredYear || '';
            document.getElementById('employeeDateOfBirth').value = employee.dateOfBirth || '';
            document.getElementById('employeeSex').value = employee.sex || 'M';
            document.getElementById('employeeSpouseDateOfBirth').value = employee.spouseDateOfBirth || 0;
            document.getElementById('employeeSpouseSex').value = employee.spouseSex || 'F';
            
            if (employee.spouseDateOfBirth > 0) {
                document.getElementById('spouseSexGroup').style.display = 'block';
            } else {
                document.getElementById('spouseSexGroup').style.display = 'none';
            }
            
            document.getElementById('editModal').style.display = 'block';
        }
        
        function closeModal() {
            document.getElementById('editModal').style.display = 'none';
        }
        
        document.getElementById('employeeSpouseDateOfBirth').addEventListener('change', function() {
            if (parseInt(this.value) > 0) {
                document.getElementById('spouseSexGroup').style.display = 'block';
            } else {
                document.getElementById('spouseSexGroup').style.display = 'none';
            }
        });
        
        async function saveEmployee(event) {
            event.preventDefault();
            
            const id = document.getElementById('employeeId').value;
            const name = document.getElementById('employeeName').value;
            const hiredYear = parseInt(document.getElementById('employeeHiredYear').value);
            const dateOfBirth = parseInt(document.getElementById('employeeDateOfBirth').value);
            const sex = document.getElementById('employeeSex').value;
            const spouseDateOfBirth = parseInt(document.getElementById('employeeSpouseDateOfBirth').value) || 0;
            const spouseSex = spouseDateOfBirth > 0 ? document.getElementById('employeeSpouseSex').value : null;
            
            let employee = {
                name: name,
                hiredYear: hiredYear,
                dateOfBirth: dateOfBirth,
                sex: sex,
                spouseDateOfBirth: spouseDateOfBirth
            };
            
            if (spouseSex) {
                employee.spouseSex = spouseSex;
            }
            
            if (id) {
                // Update existing
                employee.id = parseInt(id);
                const index = employees.findIndex(e => e.id === employee.id);
                if (index >= 0) {
                    employees[index] = employee;
                }
            } else {
                // Add new
                const maxId = employees.length > 0 ? Math.max(...employees.map(e => e.id || 0)) : 0;
                employee.id = maxId + 1;
                employees.push(employee);
            }
            
            // Save to server
            try {
                showStatus('Saving...', 'info');
                const response = await fetch('/api/employees', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json'
                    },
                    body: JSON.stringify(employees)
                });
                
                if (!response.ok) {
                    throw new Error('Failed to save');
                }
                
                showStatus('Employee saved successfully!', 'success');
                closeModal();
                renderTable();
            } catch (error) {
                showStatus('Error saving employee: ' + error.message, 'error');
            }
        }
        
        async function deleteEmployee(id) {
            if (!confirm('Are you sure you want to delete this employee?')) {
                return;
            }
            
            employees = employees.filter(e => e.id !== id);
            
            try {
                showStatus('Deleting...', 'info');
                const response = await fetch('/api/employees', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json'
                    },
                    body: JSON.stringify(employees)
                });
                
                if (!response.ok) {
                    throw new Error('Failed to delete');
                }
                
                showStatus('Employee deleted successfully!', 'success');
                renderTable();
            } catch (error) {
                showStatus('Error deleting employee: ' + error.message, 'error');
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
        
        // Close modal when clicking outside
        window.onclick = function(event) {
            const modal = document.getElementById('editModal');
            if (event.target == modal) {
                closeModal();
            }
        }
        
        async function exportToApp() {
            const appPath = document.getElementById('appPath').value.trim();
            
            if (!appPath) {
                showStatus('Please enter the iOS app Documents path first', 'error');
                return;
            }
            
            try {
                showStatus('Exporting to app...', 'info');
                const response = await fetch('/api/export', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json'
                    },
                    body: JSON.stringify({ appPath: appPath })
                });
                
                const result = await response.json();
                
                if (result.success) {
                    showStatus(result.message || 'Exported successfully!', 'success');
                } else {
                    showStatus('Export failed: ' + result.error, 'error');
                }
            } catch (error) {
                showStatus('Error exporting: ' + error.message, 'error');
            }
        }
        
        async function saveAppPath() {
            const appPath = document.getElementById('appPath').value.trim();
            
            if (!appPath) {
                showStatus('Please enter an app path first', 'error');
                return;
            }
            
            try {
                showStatus('Saving app path...', 'info');
                const response = await fetch('/api/apppath', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json'
                    },
                    body: JSON.stringify({ appPath: appPath })
                });
                
                if (!response.ok) {
                    const errorText = await response.text();
                    throw new Error('Server error: ' + response.status + ' - ' + errorText);
                }
                
                const result = await response.json();
                
                if (result.success) {
                    showStatus('App path saved successfully!', 'success');
                } else {
                    showStatus('Failed to save path: ' + (result.error || 'Unknown error'), 'error');
                }
            } catch (error) {
                console.error('Error saving path:', error);
                showStatus('Error saving path: ' + error.message, 'error');
            }
        }
        
        async function loadAppPath() {
            try {
                const response = await fetch('/api/apppath');
                const result = await response.json();
                if (result.appPath) {
                    document.getElementById('appPath').value = result.appPath;
                }
            } catch (error) {
                console.error('Error loading app path:', error);
            }
        }
        
        // Auto-load on page load
        window.addEventListener('load', () => {
            refreshList();
            loadAppPath();
        });
    </script>
</body>
</html>"""
        return html_template.replace('{FILE_PATH}', self.json_file_path)

def main():
    # Parse command line arguments
    json_path = DEFAULT_JSON_PATH
    port = DEFAULT_PORT
    
    if len(sys.argv) > 1:
        json_path = os.path.expanduser(sys.argv[1])
    if len(sys.argv) > 2:
        port = int(sys.argv[2])
    
    # Set the JSON file path for the handler
    JSONEditorHandler.json_file_path = json_path
    
    print("Starting JSON Editor Server...")
    print(f"JSON File: {json_path}")
    print(f"Port: {port}")
    print(f"Open http://localhost:{port} in your browser")
    print("Press Ctrl+C to stop")
    
    try:
        with socketserver.TCPServer(("", port), JSONEditorHandler) as httpd:
            httpd.serve_forever()
    except KeyboardInterrupt:
        print("\nServer stopped.")

if __name__ == "__main__":
    main()


