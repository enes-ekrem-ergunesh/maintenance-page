#!/bin/bash

# ##################################################################
# ##############      MAINTENANCE SCRIPT CONFIG      ###############
# ##################################################################

# Domain you want to put into maintenance
DOMAIN="example.com"

# The domain where the actual site will be temporarily available
MAINTENANCE_DOMAIN="example-maintenance.com"

# Contact email for support
CONTACT_EMAIL="myemail@example.com"

# A short description of why the site is down
MAINTENANCE_DESCRIPTION="We are currently upgrading our servers to improve performance and reliability. The system will be back online shortly."

# Estimated time of completion
COMPLETION_TIME="04:30 PM"

# Maintenance Steps - Fill in as many as you need. Leave empty to ignore.
# STATUS can be: "Completed", "In Progress", or "Pending"
# TIME can be a specific time like "02:00 PM" or a duration like "Approx. 30 mins"

# Step 1
STEP1_TEXT="Backing up application and database"
STEP1_STATUS="Completed" # Completed | In Progress | Pending
STEP1_TIME="02:15 PM"

# Step 2
STEP2_TEXT="Migrating server infrastructure"
STEP2_STATUS="In Progress"
STEP2_TIME="Until 03:30 PM"

# Step 3
STEP3_TEXT="Restoring data and testing application"
STEP3_STATUS="Pending"
STEP3_TIME="Until 04:00 PM"

# Step 4
STEP4_TEXT="Final checks and DNS propagation"
STEP4_STATUS="Pending"
STEP4_TIME="Until 04:30 PM"

# Step 5
STEP5_TEXT=""
STEP5_STATUS=""
STEP5_TIME=""


# ##################################################################
# #################      SCRIPT LOGIC (DO NOT EDIT)    #############
# ##################################################################

# --- Nginx Configuration Paths ---
NGINX_SITES_AVAILABLE="/etc/nginx/sites-available"
NGINX_SITES_ENABLED="/etc/nginx/sites-enabled"

# --- This script's directory ---
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
INDEX_TEMPLATE_PATH="$SCRIPT_DIR/maintenance_index_html.txt"
GENERATED_INDEX_PATH="$SCRIPT_DIR/index.html"

# --- Colors for output ---
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# --- Function to display error and exit ---
error_exit() {
    echo -e "${RED}ERROR: $1${NC}" >&2
    exit 1
}

# --- Function to check if running as root ---
check_root() {
    if [ "$EUID" -ne 0 ]; then
        error_exit "This script must be run as root."
    fi
}

# --- Function to generate the HTML for a single step ---
generate_step_html() {
    local text="$1"
    local status="$2"
    local time="$3"
    local html=""

    if [ -z "$text" ]; then
        return
    fi

    case "$status" in
        "Completed")
            html="
            <!-- Step: $text - Complete -->
            <div class=\"flex items-center\">
              <div class=\"flex-shrink-0\">
                <div class=\"w-8 h-8 rounded-full bg-emerald-500 text-white flex items-center justify-center\">
                  <svg class=\"w-5 h-5\" fill=\"none\" stroke=\"currentColor\" viewBox=\"0 0 24 24\" xmlns=\"http://www.w3.org/2000/svg\"><path stroke-linecap=\"round\" stroke-linejoin=\"round\" stroke-width=\"2\" d=\"M5 13l4 4L19 7\"></path></svg>
                </div>
              </div>
              <div class=\"ml-4\">
                <span class=\"font-medium text-gray-800\">$text</span>
                <span class=\"text-sm text-emerald-600 font-semibold block\">Completed</span>
              </div>
            </div>"
            ;;
        "In Progress")
            html="
            <!-- Step: $text - In Progress -->
            <div class=\"flex items-center\">
              <div class=\"flex-shrink-0\">
                <div class=\"w-8 h-8 rounded-full bg-yellow-400 text-white flex items-center justify-center animate-pulse\">
                  <svg class=\"w-5 h-5\" fill=\"none\" stroke=\"currentColor\" viewBox=\"0 0 24 24\" xmlns=\"http://www.w3.org/2000/svg\"><path stroke-linecap=\"round\" stroke-linejoin=\"round\" stroke-width=\"2\" d=\"M12 6v6m0 0v6m0-6h6m-6 0H6\"></path></svg>
                </div>
              </div>
              <div class=\"ml-4\">
                <span class=\"font-medium text-gray-800\">$text</span>
                <span class=\"text-sm text-gray-500 block\">$time</span>
              </div>
            </div>"
            ;;
        "Pending")
            html="
            <!-- Step: $text - Pending -->
            <div class=\"flex items-center opacity-50\">
              <div class=\"flex-shrink-0\">
                <div class=\"w-8 h-8 rounded-full bg-gray-300 flex items-center justify-center\">
                   <svg class=\"w-5 h-5 text-gray-600\" fill=\"none\" stroke=\"currentColor\" viewBox=\"0 0 24 24\" xmlns=\"http://www.w3.org/2000/svg\"><path stroke-linecap=\"round\" stroke-linejoin=\"round\" stroke-width=\"2\" d=\"M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z\"></path></svg>
                </div>
              </div>
              <div class=\"ml-4\">
                <span class=\"font-medium text-gray-800\">$text</span>
                <span class=\"text-sm text-gray-500 block\">$time</span>
              </div>
            </div>"
            ;;
    esac
    echo "$html"
}

# --- Function to generate the full maintenance page ---
generate_maintenance_page() {
    echo "Generating maintenance page..."
    local steps_html=""
    steps_html+=$(generate_step_html "$STEP1_TEXT" "$STEP1_STATUS" "$STEP1_TIME")
    steps_html+=$(generate_step_html "$STEP2_TEXT" "$STEP2_STATUS" "$STEP2_TIME")
    steps_html+=$(generate_step_html "$STEP3_TEXT" "$STEP3_STATUS" "$STEP3_TIME")
    steps_html+=$(generate_step_html "$STEP4_TEXT" "$STEP4_STATUS" "$STEP4_TIME")
    steps_html+=$(generate_step_html "$STEP5_TEXT" "$STEP5_STATUS" "$STEP5_TIME")

    # Create a temporary file for sed
    local temp_template=$(mktemp)
    cp "$INDEX_TEMPLATE_PATH" "$temp_template"

    # Replace placeholders
    sed -i "s|{{MAINTENANCE_DESCRIPTION}}|$MAINTENANCE_DESCRIPTION|g" "$temp_template"
    sed -i "s|{{COMPLETION_TIME}}|$COMPLETION_TIME|g" "$temp_template"
    sed -i "s|{{CONTACT_EMAIL}}|$CONTACT_EMAIL|g" "$temp_template"

    # This is a bit tricky with sed, we'll use a placeholder and then replace it
    # The placeholder <!-- STEPS_PLACEHOLDER --> must be on its own line in index.html
    local temp_steps=$(mktemp)
    echo "$steps_html" > "$temp_steps"
    sed -i -e "/<!-- STEPS_PLACEHOLDER -->/r $temp_steps" -e "/<!-- STEPS_PLACEHOLDER -->/d" "$temp_template"

    # Move the final generated file
    mv "$temp_template" "$GENERATED_INDEX_PATH"
    rm "$temp_steps"
    echo -e "${GREEN}Maintenance page generated successfully at $GENERATED_INDEX_PATH${NC}"
}


# --- Function to start maintenance ---
start_maintenance() {
    check_root
    echo -e "${YELLOW}--- Starting Maintenance Mode for $DOMAIN ---${NC}"

    # Check for required config files
    [ ! -f "$NGINX_SITES_AVAILABLE/$DOMAIN" ] && error_exit "Nginx config for $DOMAIN not found."
    [ ! -f "$NGINX_SITES_AVAILABLE/$MAINTENANCE_DOMAIN" ] && error_exit "Nginx config for $MAINTENANCE_DOMAIN not found."

    # Backup original configs
    echo "Backing up Nginx configurations..."
    cp "$NGINX_SITES_AVAILABLE/$DOMAIN" "$NGINX_SITES_AVAILABLE/$DOMAIN.bak"
    cp "$NGINX_SITES_AVAILABLE/$MAINTENANCE_DOMAIN" "$NGINX_SITES_AVAILABLE/$MAINTENANCE_DOMAIN.bak"
    echo -e "${GREEN}Backups created successfully.${NC}"

    # Generate the maintenance page
    generate_maintenance_page

    chown $USER:$USER "$GENERATED_INDEX_PATH"
    chmod 755 "$GENERATED_INDEX_PATH"

    # Modify Nginx configs
    echo "Modifying Nginx configurations..."

    # 1. Modify the original domain's config to serve the maintenance page
    # We will point its root to this script's directory and serve the generated index
    CONF_FILE="$NGINX_SITES_AVAILABLE/$DOMAIN"

  cat > "$CONF_FILE" <<EOF
server {
    listen 80;
    server_name $DOMAIN;

    root $SCRIPT_DIR;
    index index.html;

    location / {
        try_files \$uri \$uri/ =404;
    }
}
EOF
  echo "Reloading Nginx to use certbot..."
  nginx -t || error_exit "Config test failed."
  systemctl reload nginx

  echo -e "${YELLOW}Running certbot to reuse existing certificates...${NC}"
  sudo certbot --nginx -d "$DOMAIN" -d "www.$DOMAIN" --non-interactive --agree-tos --email "$CONTACT_EMAIL" --redirect || {
    error_exit "Certbot failed. Check if domain points to this server and try again."
  }

    # 2. Modify the maintenance domain's config to serve the actual site
    # This is done by simply copying the original domain's config over
    cp "$NGINX_SITES_AVAILABLE/$DOMAIN.bak" "$NGINX_SITES_AVAILABLE/$MAINTENANCE_DOMAIN"
    
    # Replace all example.com with maintenance.com, except in 'root' line
    sed -i "/root/!s/\b$DOMAIN\b/$MAINTENANCE_DOMAIN/g" "$NGINX_SITES_AVAILABLE/$MAINTENANCE_DOMAIN"


    echo -e "${GREEN}Nginx configurations modified.${NC}"

    # Test and reload Nginx
    echo "Testing Nginx configuration..."
    if nginx -t; then
        echo "Reloading Nginx..."
        systemctl reload nginx
        echo -e "${GREEN}--- Maintenance Mode is now ACTIVE ---${NC}"
        echo "Your site is now in maintenance mode."
        echo "The maintenance page is served on: ${YELLOW}http://$DOMAIN${NC}"
        echo "The original site is available at: ${YELLOW}http://$MAINTENANCE_DOMAIN${NC}"
    else
        error_exit "Nginx configuration test failed. Reverting changes."
        restore_maintenance "failed"
    fi
}

# --- Function to restore from maintenance ---
restore_maintenance() {
    check_root
    echo -e "${YELLOW}--- Restoring from Maintenance Mode for $DOMAIN ---${NC}"

    # Check for backup files
    if [ ! -f "$NGINX_SITES_AVAILABLE/$DOMAIN.bak" ] || [ ! -f "$NGINX_SITES_AVAILABLE/$MAINTENANCE_DOMAIN.bak" ]; then
        error_exit "Backup files not found. Cannot restore automatically."
    fi

    # Restore original configs
    echo "Restoring Nginx configurations from backup..."
    mv "$NGINX_SITES_AVAILABLE/$DOMAIN.bak" "$NGINX_SITES_AVAILABLE/$DOMAIN"
    mv "$NGINX_SITES_AVAILABLE/$MAINTENANCE_DOMAIN.bak" "$NGINX_SITES_AVAILABLE/$MAINTENANCE_DOMAIN"
    echo -e "${GREEN}Configurations restored.${NC}"

    # Clean up generated maintenance page
    [ -f "$GENERATED_INDEX_PATH" ] && rm "$GENERATED_INDEX_PATH"

    # Test and reload Nginx
    if [ "$1" != "failed" ]; then
      echo "Testing Nginx configuration..."
      if nginx -t; then
          echo "Reloading Nginx..."
          systemctl reload nginx
          echo -e "${GREEN}--- Maintenance Mode is now INACTIVE ---${NC}"
          echo "Your site ${YELLOW}$DOMAIN${NC} is live again."
      else
          error_exit "Nginx configuration test failed after restore. Please check your configs manually."
      fi
    fi
}

# --- Function to update maintenance page only ---
update_maintenance_page() {
    check_root
    echo -e "${YELLOW}--- Updating Maintenance Page for $DOMAIN ---${NC}"
    
    # Make sure maintenance mode is active
    CONF_FILE="$NGINX_SITES_AVAILABLE/$DOMAIN"
    if ! grep -q "root $SCRIPT_DIR;" "$CONF_FILE"; then
        error_exit "Maintenance mode does not appear to be active. Aborting update."
    fi

    # Regenerate the maintenance HTML
    generate_maintenance_page

    chown $USER:$USER "$GENERATED_INDEX_PATH"
    chmod 755 "$GENERATED_INDEX_PATH"

    # Reload Nginx to reflect changes
    echo "Reloading Nginx..."
    nginx -t || error_exit "Nginx config test failed after update."
    systemctl reload nginx
    echo -e "${GREEN}Maintenance page updated successfully.${NC}"
}

case "$1" in
    start)
        start_maintenance
        ;;
    stop)
        restore_maintenance
        ;;
    update)
        update_maintenance_page
        ;;
    *)
        echo "Usage: $0 {start|stop|update}"
        exit 1
        ;;
esac

exit 0
