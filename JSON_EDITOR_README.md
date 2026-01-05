# JSON Editor Server

A simple localhost web server for editing the `employees.json` file during development.

## Usage

### Option 1: Using Python (Recommended)

1. Make sure you have Python 3 installed
2. Run the server:
   ```bash
   python3 json_editor_server.py [json_file_path] [port]
   ```

   Examples:
   ```bash
   # Use default path (~/Documents/employees.json) and default port (8080)
   python3 json_editor_server.py
   
   # Specify custom JSON file path
   python3 json_editor_server.py /path/to/employees.json
   
   # Specify custom JSON file path and port
   python3 json_editor_server.py /path/to/employees.json 3000
   ```

3. Open your browser and navigate to:
   ```
   http://localhost:8080
   ```

4. The page will automatically load the JSON file. You can:
   - Edit the JSON directly in the text area
   - Click "Format JSON" to auto-format
   - Click "Validate JSON" to check for errors
   - Click "Save JSON" to save changes (creates a backup automatically)

### Option 2: Using Swift (Advanced)

If you prefer to use the Swift version:

1. Make the script executable:
   ```bash
   chmod +x json_editor_server.swift
   ```

2. Run it:
   ```bash
   swift json_editor_server.swift [json_file_path] [port]
   ```

## Features

- **Load JSON**: Loads the current employees.json file
- **Save JSON**: Saves changes and creates a backup (.backup file)
- **Format JSON**: Auto-formats the JSON with proper indentation
- **Validate JSON**: Checks if the JSON is valid before saving
- **Auto-backup**: Creates a backup file before saving changes

## Finding the JSON File Path

The employees.json file is typically located in:
- iOS Simulator: `~/Library/Developer/CoreSimulator/Devices/[DEVICE_ID]/data/Containers/Data/Application/[APP_ID]/Documents/employees.json`
- macOS: `~/Documents/employees.json` (if using the default path)

To find the exact path in your iOS app, you can add this to your code temporarily:
```swift
let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
print("Documents path: \(documentsPath)")
```

## Notes

- The server runs on localhost only (not accessible from other machines)
- Changes are saved directly to the JSON file
- A backup is created before each save (employees.json.backup)
- The server must be restarted if you change the JSON file path

