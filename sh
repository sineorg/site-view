#!/bin/bash

# Sine Installer -- v2 (Bash Version)
# Converted from C# implementation

set -e  # Exit on any error

# Global variables
PLATFORM=""
HOME_DIR="$HOME"
IS_LINUX=false
IS_COSINE=true
SINE_BRANCH=""
TEMP_USERNAME=""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Get platform
get_platform() {
    case "$(uname -s)" in
        Linux*)     PLATFORM="linux" ;;
        Darwin*)    PLATFORM="darwin" ;;
        CYGWIN*|MINGW*|MSYS*) PLATFORM="win32" ;;
        *)          PLATFORM="unknown" ;;
    esac
    
    if [ "$PLATFORM" = "linux" ]; then
        IS_LINUX=true
    fi
    
    if [ "$IS_COSINE" = true ]; then
        SINE_BRANCH="cosine"
    else
        SINE_BRANCH="main"
    fi
}

# Check if platform is supported
is_supported_platform() {
    case "$PLATFORM" in
        win32|darwin|linux) return 0 ;;
        *) return 1 ;;
    esac
}

# Exit function
exit_program() {
    echo
    read -p "Enter anything to exit: " -r
    exit 1
}

# Prompt for input
prompt_input() {
    local message="$1"
    echo -n "$message "
    read -r input
    echo "$input"
}

# Prompt for selection from options
prompt_select() {
    local message="$1"
    shift
    local options=("$@")
    
    echo "$message"
    
    for i in "${!options[@]}"; do
        echo "$((i + 1)). ${options[i]}"
    done
    
    while true; do
        echo -n "Enter your choice (1-${#options[@]}): "
        read -r choice
        
        if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#options[@]}" ]; then
            echo "${options[$((choice - 1))]}"
            return
        fi
        
        echo "Invalid choice. Please try again."
    done
}

# Manual location prompt
manual_location_prompt() {
    local prompt_for="$1"
    local location=""
    local not_first_loop=false
    
    while [ ! -d "$location" ] && [ ! -f "$location" ]; do
        if [ "$not_first_loop" = true ]; then
            echo
            echo "You can't input non-existent paths."
        else
            not_first_loop=true
        fi
        
        location=$(prompt_input "Enter the location of $prompt_for on your system:")
    done
    
    echo "$location"
}

# Auto detect path
auto_detect_path() {
    local browser="$1"
    local is_profile="$2"
    local temp_username="$3"
    
    declare -A firefox_locations=(
        ["win32"]="Mozilla/Firefox"
        ["darwin"]="Firefox"
        ["linux"]=".mozilla/firefox"
    )
    
    declare -A floorp_locations=(
        ["win32"]="Floorp"
        ["darwin"]="Floorp" 
        ["linux"]=".floorp"
    )
    
    declare -A zen_locations=(
        ["win32"]="zen"
        ["darwin"]="Zen"
        ["linux"]=".zen"
    )
    
    declare -A mullvad_locations=(
        ["win32"]="Mullvad/MullvadBrowser"
        ["darwin"]="MullvadBrowser"
        ["linux"]=".mullvad-browser"
    )
    
    declare -A waterfox_locations=(
        ["win32"]="Waterfox"
        ["darwin"]="Waterfox"
        ["linux"]=".waterfox"
    )
    
    local location=""
    
    case "$browser" in
        "Firefox") 
            case "$PLATFORM" in
                win32) location="${firefox_locations[win32]}" ;;
                darwin) location="${firefox_locations[darwin]}" ;;
                linux) location="${firefox_locations[linux]}" ;;
            esac
            ;;
        "Floorp")
            case "$PLATFORM" in
                win32) location="${floorp_locations[win32]}" ;;
                darwin) location="${floorp_locations[darwin]}" ;;
                linux) location="${floorp_locations[linux]}" ;;
            esac
            ;;
        "Zen")
            case "$PLATFORM" in
                win32) location="${zen_locations[win32]}" ;;
                darwin) location="${zen_locations[darwin]}" ;;
                linux) location="${zen_locations[linux]}" ;;
            esac
            ;;
        "Mullvad")
            case "$PLATFORM" in
                win32) location="${mullvad_locations[win32]}" ;;
                darwin) location="${mullvad_locations[darwin]}" ;;
                linux) location="${mullvad_locations[linux]}" ;;
            esac
            ;;
        "Waterfox")
            case "$PLATFORM" in
                win32) location="${waterfox_locations[win32]}" ;;
                darwin) location="${waterfox_locations[darwin]}" ;;
                linux) location="${waterfox_locations[linux]}" ;;
            esac
            ;;
        *)
            echo
            echo "We do not currently support automatic location detection of $browser$([ "$is_profile" = true ] && echo "'s profiles folder" || echo "")."
            echo "If you believe we should support this browser, you may post an issue on our github page."
            return 1
            ;;
    esac
    
    if [ -z "$location" ]; then
        echo
        echo "We do not currently support automatic location detection of $browser$([ "$is_profile" = true ] && echo "'s profiles folder" || echo "") on $PLATFORM."
        echo "If you believe we should support this platform, you may post an issue on our github page."
        return 1
    fi
    
    local full_path=""
    
    if [ "$is_profile" = true ]; then
        case "$PLATFORM" in
            win32)
                full_path="$HOME_DIR/AppData/Roaming/$location/Profiles"
                ;;
            darwin)
                full_path="$HOME_DIR/Library/Application Support/$location/Profiles"
                ;;
            linux)
                local username="${temp_username:-$(whoami)}"
                full_path="/home/$username/$location"
                ;;
        esac
    else
        full_path="$location"
    fi
    
    if [ -d "$full_path" ]; then
        if [ "$is_profile" != true ]; then
            echo
        fi
        echo "Successfully found the $([ "$is_profile" = true ] && echo "profiles folder" || echo "installation directory") for $browser on $PLATFORM."
        if [ "$is_profile" = true ]; then
            echo
        fi
        echo "$full_path"
        return 0
    fi
    
    echo
    echo "We could not find $browser$([ "$is_profile" = true ] && echo "'s profiles folder" || echo "") on your system."
    return 1
}

# Get profile directory
get_profile_dir() {
    local browser="$1"
    local temp_username="$2"
    
    local location
    if location=$(auto_detect_path "$browser" true "$temp_username"); then
        echo "$location"
        return 0
    fi
    
    echo
    echo "Unable to automatically detect the location of $browser's profile folder, proceeding with manual prompt."
    manual_location_prompt "$browser's profile folder"
}

# Get profiles from profiles.ini
get_profiles() {
    local profile_dir="$1"
    local ini_path
    
    if [ "$IS_LINUX" = true ]; then
        ini_path="$profile_dir/profiles.ini"
    else
        ini_path="$(dirname "$profile_dir")/profiles.ini"
    fi
    
    local profiles=()
    
    if [ ! -f "$ini_path" ]; then
        print_error "profiles.ini not found at $ini_path"
        return 1
    fi
    
    local current_profile_path=""
    
    while IFS= read -r line; do
        line=$(echo "$line" | tr -d '\r' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        
        if [[ "$line" =~ ^\[Profile ]]; then
            current_profile_path=""
        elif [[ "$line" =~ ^Path= ]]; then
            current_profile_path="${line#Path=}"
            if [ -n "$current_profile_path" ]; then
                local profile_name=$(basename "$current_profile_path")
                local full_path="$profile_dir/$profile_name"
                if [ -d "$full_path" ]; then
                    profiles+=("$profile_name|$full_path")
                fi
            fi
        fi
    done < "$ini_path"
    
    if [ ${#profiles[@]} -eq 0 ]; then
        print_error "No profiles found in the profile directory."
        return 1
    fi
    
    printf '%s\n' "${profiles[@]}"
}

# Prompt for username (Linux only)
prompt_username() {
    prompt_input "Enter the name of the username to install Sine into:"
}

# Download file
download_file() {
    local url="$1"
    local dest_path="$2"
    
    mkdir -p "$(dirname "$dest_path")"
    
    if command -v wget >/dev/null 2>&1; then
        wget -q -O "$dest_path" "$url"
    elif command -v curl >/dev/null 2>&1; then
        curl -s -L -o "$dest_path" "$url"
    else
        print_error "Neither wget nor curl found. Please install one of them."
        exit_program
    fi
}

# Setup file download
setup_file_download() {
    local existing_path="$1"
    local file="$2"
    local url="$3"
    
    local dest="$existing_path/$file"
    
    if download_file "$url" "$dest"; then
        echo "Installed $file"
    else
        print_error "Failed to install $file"
        exit_program
    fi
}

# Install Fx-AutoConfig
install_fx_autoconfig() {
    local profile_path="$1"
    local program_path="$2"
    
    echo
    echo "Installing Fx-AutoConfig..."
    echo
    
    local program_files=(
        "config.js"
        "defaults/pref/config-prefs.js"
    )
    
    local profile_files=(
        "utils/boot.sys.mjs"
        "utils/chrome.manifest"
        "utils/fs.sys.mjs"
        "utils/module_loader.mjs"
        "utils/uc_api.sys.mjs"
        "utils/utils.sys.mjs"
    )
    
    for file in "${program_files[@]}"; do
        local url="https://raw.githubusercontent.com/MrOtherGuy/fx-autoconfig/f1f61958491c18e690bed8e04e89dd3a8e4a6c4d/program/$file"
        setup_file_download "$program_path" "$file" "$url"
    done
    
    for file in "${profile_files[@]}"; do
        local url="https://raw.githubusercontent.com/MrOtherGuy/fx-autoconfig/f1f61958491c18e690bed8e04e89dd3a8e4a6c4d/profile/chrome/$file"
        setup_file_download "$profile_path" "chrome/$file" "$url"
    done
    
    echo
    echo "Fx-AutoConfig has been installed successfully!"
}

# Download and extract zip
download_and_extract_zip() {
    local zip_url="$1"
    local extract_path="$2"
    
    mkdir -p "$extract_path"
    local temp_zip="/tmp/sine_engine_$(date +%s).zip"
    
    echo "Downloading zip file..."
    
    if download_file "$zip_url" "$temp_zip"; then
        echo "Download completed. Extracting files..."
        
        if command -v unzip >/dev/null 2>&1; then
            unzip -o -q "$temp_zip" -d "$extract_path"
            echo "Files successfully extracted to the selected profile folder."
        else
            print_error "unzip command not found. Please install unzip."
            rm -f "$temp_zip"
            exit_program
        fi
        
        rm -f "$temp_zip"
    else
        print_error "Failed to download zip file"
        rm -f "$temp_zip"
        exit_program
    fi
}

# Install Sine
install_sine() {
    local profile_path="$1"
    local temp_username="$2"
    
    echo
    echo "Installing Sine..."
    
    local zip_url="https://raw.githubusercontent.com/CosmoCreeper/Sine/$SINE_BRANCH/deployment/engine.zip"
    download_and_extract_zip "$zip_url" "$profile_path/chrome/JS"
    
    echo
    echo "Sine has been installed successfully!"
    
    if [ "$IS_LINUX" = true ] && [ -n "$temp_username" ]; then
        chown -R "$temp_username:$temp_username" "$profile_path/chrome/JS" 2>/dev/null || true
        echo
        echo "Fixed permission issues."
    fi
}

# Uninstall Sine
uninstall_sine() {
    local profile_path="$1"
    
    echo
    echo "Uninstalling Sine..."
    
    local sine_path="$profile_path/chrome/JS/sine.uc.mjs"
    if [ ! -f "$sine_path" ]; then
        echo "Sine is not installed in the specified profile."
        return
    fi
    
    rm -f "$sine_path"
    echo "Successfully removed the control script."
    
    local engine_path="$profile_path/chrome/JS/engine"
    if [ -d "$engine_path" ]; then
        rm -rf "$engine_path"
        echo "Successfully removed the Sine engine."
    fi
}

# Get version from JSON
get_version_only() {
    local url="https://raw.githubusercontent.com/CosmoCreeper/Sine/$SINE_BRANCH/deployment/engine.json"
    local temp_file="/tmp/engine_version_$(date +%s).json"
    
    if download_file "$url" "$temp_file"; then
        # Extract version using basic tools (assuming jq might not be available)
        if command -v jq >/dev/null 2>&1; then
            jq -r '.version' "$temp_file" 2>/dev/null || echo ""
        else
            # Fallback parsing without jq
            grep -o '"version"[[:space:]]*:[[:space:]]*"[^"]*"' "$temp_file" | cut -d'"' -f4 2>/dev/null || echo ""
        fi
        rm -f "$temp_file"
    else
        echo ""
    fi
}

# Set Sine preferences
set_sine_pref() {
    local profile_path="$1"
    local prefs_path="$profile_path/prefs.js"
    
    local current_time=$(date "+%Y-%m-%d %H:%M")
    local version
    version=$(get_version_only)
    
    # Check and add updated-at preference
    if ! grep -q 'user_pref("sine.updated-at"' "$prefs_path" 2>/dev/null; then
        echo "user_pref(\"sine.updated-at\", \"$current_time\");" >> "$prefs_path"
    fi
    
    # Check and add version preference
    if ! grep -q 'user_pref("sine.version"' "$prefs_path" 2>/dev/null; then
        echo "user_pref(\"sine.version\", \"$version\");" >> "$prefs_path"
    fi
    
    # Check and add latest-version preference
    if ! grep -q 'user_pref("sine.latest-version"' "$prefs_path" 2>/dev/null; then
        echo "user_pref(\"sine.latest-version\", \"$version\");" >> "$prefs_path"
    fi
}

# Get browser selection
get_browser() {
    local browsers=("Firefox" "Zen" "Floorp" "Mullvad" "Waterfox")
    local browser
    browser=$(prompt_select "What browser do you wish to install Sine on (you may select canary/beta builds later)?" "${browsers[@]}")
    
    echo
    
    local version=""
    case "$browser" in
        "Firefox")
            local firefox_versions=("Stable" "Developer Edition" "Nightly")
            version=$(prompt_select "What version of Firefox do you use (stable will work with beta)?" "${firefox_versions[@]}")
            ;;
        "Zen")
            local zen_versions=("Beta" "Twilight")
            version=$(prompt_select "What version of Zen do you use (beta is default)?" "${zen_versions[@]}")
            ;;
        "Mullvad")
            local mullvad_versions=("Stable" "Alpha")
            version=$(prompt_select "What version of Mullvad do you use?" "${mullvad_versions[@]}")
            ;;
    esac
    
    if [ -n "$version" ]; then
        echo "$browser $version"
    else
        echo "$browser"
    fi
}

# Close browser processes
close_browser() {
    local browser="$1"
    local process_name=""
    
    case "$browser" in
        "Firefox"*) process_name="firefox" ;;
        "Zen"*) process_name="zen" ;;
        "Floorp"*) process_name="floorp" ;;
        "Mullvad"*) process_name="mullvadbrowser" ;;
        "Waterfox"*) process_name="waterfox" ;;
    esac
    
    echo
    echo "Killing all processes of $process_name..."
    
    local killed_count=0
    if command -v pkill >/dev/null 2>&1; then
        killed_count=$(pgrep -c "$process_name" 2>/dev/null || echo "0")
        pkill "$process_name" 2>/dev/null || true
    elif command -v killall >/dev/null 2>&1; then
        killall "$process_name" 2>/dev/null || true
        killed_count="unknown"
    fi
    
    echo "Killed $killed_count processes of $process_name."
}

# Get browser location (simplified for bash)
get_browser_location() {
    local browser="$1"
    
    # For simplicity, we'll use auto-detection or manual input
    local location
    if location=$(auto_detect_path "$browser" false); then
        local valid_path
        valid_path=$(prompt_input "Do you wish to install Sine in $location (y/N)?")
        if [[ "$valid_path" =~ ^[Yy] ]]; then
            echo "$location"
            return
        fi
    fi
    
    echo
    echo "Unable to automatically detect the location of $browser, proceeding with manual prompt."
    manual_location_prompt "$browser"
}

# Clear startup cache
clear_startup_cache() {
    local browser="$1"
    local selected_profile="$2"
    
    if [ "$PLATFORM" = "win32" ]; then
        local local_dir="${selected_profile/Roaming/Local}"
        if [ -d "$local_dir/startupCache" ]; then
            close_browser "$browser"
            rm -rf "$local_dir/startupCache"
        fi
    fi
}

# Prompt profile selection
prompt_profile_selection() {
    local profiles_array=("$@")
    local profile_names=()
    local profile_paths=()
    
    for profile in "${profiles_array[@]}"; do
        IFS='|' read -r name path <<< "$profile"
        profile_names+=("$name")
        profile_paths+=("$path")
    done
    
    local selected_name
    selected_name=$(prompt_select "Which profile do you want to install Sine on?" "${profile_names[@]}")
    
    for i in "${!profile_names[@]}"; do
        if [ "${profile_names[i]}" = "$selected_name" ]; then
            echo "${profile_paths[i]}"
            return
        fi
    done
}

# Main function
main() {
    echo "==> Sine Installer -- v2 <=="
    echo
    
    get_platform
    
    if ! is_supported_platform; then
        echo "Sorry, you don't use a supported platform for the auto-installer."
        echo "Please consider manually installing or post about it on our github repository."
        exit_program
    fi
    
    # Check if running as root on Linux
    if [ "$IS_LINUX" = true ] && [ "$(id -u)" -ne 0 ]; then
        echo "This script must be run as root on Linux."
        exit_program
    fi
    
    local browser
    browser=$(get_browser)
    
    local browser_location
    browser_location=$(get_browser_location "$browser")
    
    local temp_username=""
    if [ "$IS_LINUX" = true ]; then
        temp_username=$(prompt_username)
        TEMP_USERNAME="$temp_username"
    fi
    
    local profile_dir
    if ! profile_dir=$(get_profile_dir "$(echo "$browser" | cut -d' ' -f1)" "$temp_username"); then
        print_error "Profile directory error"
        exit_program
    fi
    
    if [ ! -d "$profile_dir" ]; then
        print_error "Profile directory not found at $profile_dir"
        exit_program
    fi
    
    local profiles
    if ! profiles=($(get_profiles "$profile_dir")); then
        echo "No profiles found in the profile directory."
        exit_program
    fi
    
    local selected_profile
    selected_profile=$(prompt_profile_selection "${profiles[@]}")
    
    # Check if Sine is already installed
    if [ -f "$selected_profile/chrome/JS/sine.uc.mjs" ]; then
        local should_remove
        should_remove=$(prompt_input "Do you wish to remove Sine from the selected profile (y/N)?")
        if [[ "$should_remove" =~ ^[Yy] ]]; then
            uninstall_sine "$selected_profile"
            echo
            exit 0
        fi
    fi
    
    install_fx_autoconfig "$selected_profile" "$browser_location"
    install_sine "$selected_profile" "$temp_username"
    set_sine_pref "$selected_profile"
    
    clear_startup_cache "$browser" "$selected_profile"
    
    echo
    exit 0
}

# Run main function
main "$@"