# Nginx Maintenance Page Script

A simple, yet powerful Bash script to put your Nginx-powered website into a beautiful and informative maintenance mode with real-time progress updates. 🚀

This script automates the process of switching your live site to a maintenance page, redirecting the actual application to a temporary domain, and restoring everything back to normal once you're done.

<p align="center">
<img src="https://i.ibb.co/Z6FLLQDw/maintenance.png" alt="Maintenance Page Screenshot 1" width="400" height="390"> <img src="https://i.ibb.co/PvcPvNf3/maintenance2.png" alt="Maintenance Page Screenshot 2" width="400" height="390">
</p>

***

## Features

-   **Easy Configuration**: All settings are at the top of the `maintenance.sh` script. No need to dig through the code.
-   **Dynamic Progress Steps**: Define maintenance tasks and update their status ("Completed", "In Progress", "Pending") on the fly.
-   **Temporary Site Access**: The script moves your live site to a temporary domain, so you can still access and test it during maintenance.
-   **Automatic Nginx Handling**: Automatically backs up and modifies Nginx server blocks.
-   **Safe Restore**: Reverts all changes and brings your site back online with a single command.
-   **Live Updates**: Update the progress on the maintenance page without taking the entire system down and up again.

***

## Prerequisites

Before you begin, ensure you have the following set up:

1.  A server running a Linux distribution.
2.  **Nginx** installed and configured.
3.  **Root access** (`sudo`) to run the script.
4.  **Two domain names** pointing to your server's IP address:
    * Your main domain (e.g., `example.com`).
    * A temporary domain for accessing the site during maintenance (e.g., `example-maintenance.com`).
5.  **Certbot** installed for SSL certificate management.

***

## Installation & Setup

1.  **Clone the repository** to a location on your server, for example, `/opt/maintenance`:
    ```bash
    git clone [https://github.com/enes-ekrem-ergunesh/maintenance-page.git](https://github.com/enes-ekrem-ergunesh/maintenance-page.git) /opt/maintenance
    cd /opt/maintenance
    ```

2.  **Make the script executable**:
    ```bash
    chmod +x maintenance.sh
    ```

3.  **Prepare Nginx Server Blocks**:
    You must have two Nginx server block configuration files in `/etc/nginx/sites-available/`:
    -   One for your main domain: `/etc/nginx/sites-available/example.com`
    -   One for your temporary domain: `/etc/nginx/sites-available/example-maintenance.com`

    The script will manage enabling/disabling and modifying these files. The content of `example-maintenance.com` can be a minimal placeholder initially, as the script will overwrite it.

***

## Configuration

Open the `maintenance.sh` file with a text editor and modify the `MAINTENANCE SCRIPT CONFIG` section at the top.

```bash
# Domain you want to put into maintenance
DOMAIN="example.com"

# The domain where the actual site will be temporarily available
MAINTENANCE_DOMAIN="example-maintenance.com"

# Contact email for support
CONTACT_EMAIL="myemail@example.com"

# A short description of why the site is down
MAINTENANCE_DESCRIPTION="We are currently upgrading our servers..."

# Estimated time of completion
COMPLETION_TIME="04:30 PM"

# Maintenance Steps - Fill in as many as you need
# STATUS can be: "Completed", "In Progress", or "Pending"
STEP1_TEXT="Backing up application and database"
STEP1_STATUS="Pending"
STEP1_TIME="02:15 PM"

STEP2_TEXT="Migrating server infrastructure"
STEP2_STATUS="Pending"
STEP2_TIME="Until 03:30 PM"
# ... and so on
```

***

## Usage

The script is controlled with simple `start`, `stop`, and `update` commands. **It must be run with `sudo`**.

### To Start Maintenance

This command will back up your current Nginx configs, generate the `index.html` maintenance page, and reconfigure Nginx to display it.

```bash
sudo ./maintenance.sh start
```

Your site will now be in maintenance mode.
-   `http://example.com` will show the maintenance page.
-   `http://example-maintenance.com` will show your actual website.

### To Update Maintenance Progress

If you've completed a step and want to update the status on the page, simply edit the `STEPx_STATUS` variables in `maintenance.sh` and run the `update` command. This will regenerate the HTML without interrupting the service.

```bash
# First, edit the script to change a step's status, e.g., STEP1_STATUS="Completed"
# Then run:
sudo ./maintenance.sh update
```

### To Stop Maintenance

This command restores your original Nginx configurations, deletes the generated `index.html`, and brings your main site back online.

```bash
sudo ./maintenance.sh stop
```

Your website at `http://example.com` is now live again! 🎉

***

## How It Works

-   **`start`**: The script backs up your Nginx config for `DOMAIN` and `MAINTENANCE_DOMAIN`. It then overwrites the `DOMAIN` config to serve the locally generated `index.html`. Finally, it copies the original `DOMAIN` config to the `MAINTENANCE_DOMAIN` config (adjusting the domain name inside) and reloads Nginx.
-   **`update`**: It just regenerates the `index.html` file from the template and script variables. Since Nginx is already serving this file, no configuration changes are needed.
-   **`stop`**: It simply restores the `.bak` configuration files and reloads Nginx.

***

## License

This project is licensed under the MIT License.