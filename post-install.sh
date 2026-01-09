#!/bin/bash

# Capture Spin Variables
SPIN_ACTION=${SPIN_ACTION:-"install"}
SPIN_PHP_VERSION="${SPIN_PHP_VERSION:-8.5}"
SPIN_PHP_VARIATION="${SPIN_PHP_VARIATION:-fpm-nginx}"
SPIN_PHP_DOCKER_INSTALLER_IMAGE="${SPIN_PHP_DOCKER_INSTALLER_IMAGE:-serversideup/php:${SPIN_PHP_VERSION}-cli}"
SPIN_PHP_DOCKER_BASE_IMAGE="${SPIN_PHP_DOCKER_BASE_IMAGE:-serversideup/php:${SPIN_PHP_VERSION}-fpm-nginx-alpine}"

# Set project variables

spin_database="mysql"
javascript_package_manager="yarn"
php_dockerfile="Dockerfile"
project_dir=${SPIN_PROJECT_DIRECTORY:-"$(pwd)/template"}
template_src_dir=${SPIN_TEMPLATE_TEMPORARY_SRC_DIR:-"$(pwd)"}

# Initialize the service variables
queue=""
mysql="1"

###############################################
# Functions
###############################################
add_php_extensions() {
    echo "${BLUE}Adding custom PHP extensions...${RESET}"
    local dockerfile="$project_dir/$php_dockerfile"
    
    # Check if Dockerfile exists
    if [ ! -f "$dockerfile" ]; then
        echo "Error: $dockerfile not found."
        return 1
    fi
    
    # Uncomment the USER root line
    line_in_file --action replace --file "$dockerfile" "# USER root" "USER root"
    
    # Add RUN command to install extensions
    local extensions_string="${php_extensions[*]}"
    line_in_file --action replace --file "$dockerfile" "# RUN install-php-extensions" "RUN install-php-extensions $extensions_string"
    
    echo "Custom PHP extensions added."
}



configure_mysql() {
    local service_name="mysql"
    echo "$service_name: Configuring MySQL database..."
    
    # Update the Laravel .env files with MySQL configuration
    line_in_file --action replace --file "$project_dir/.env" --file "$project_dir/.env.example" "DB_CONNECTION" "DB_CONNECTION=mysql"
    line_in_file --action replace --file "$project_dir/.env" --file "$project_dir/.env.example" "DB_HOST" "DB_HOST=mysql"
    line_in_file --action replace --file "$project_dir/.env" --file "$project_dir/.env.example" "DB_PORT" "DB_PORT=3306"
    line_in_file --action replace --file "$project_dir/.env" --file "$project_dir/.env.example" "DB_DATABASE" "DB_DATABASE=laravel"
    line_in_file --action replace --file "$project_dir/.env" --file "$project_dir/.env.example" "DB_USERNAME" "DB_USERNAME=laravel"
    line_in_file --action replace --file "$project_dir/.env" --file "$project_dir/.env.example" "DB_PASSWORD" "DB_PASSWORD=secret"
    
    echo "$service_name: MySQL configuration complete."
}

configure_queue() {
    local service_name="queue"
    echo "$service_name: Configuring Laravel Queue..."
    
    # Update the Laravel .env files with database queue driver
    line_in_file --action replace --file "$project_dir/.env" --file "$project_dir/.env.example" "QUEUE_CONNECTION" "QUEUE_CONNECTION=database"
    
    echo "$service_name: Queue configuration complete."
    echo "${YELLOW}Note: Run 'php artisan queue:table' and 'php artisan migrate' to create the jobs table.${RESET}"
}

initialize_git_repository() {
    local current_dir=""
    current_dir=$(pwd)

    cd "$project_dir" || exit
    echo "Initializing Git repository..."
    git init

    cd "$current_dir" || exit
}

install_node_dependencies() {
    if [[ ! -d "$project_dir" ]]; then
        echo "Error: Project directory '$project_dir' does not exist." >&2
        return 1
    fi

    if ! cd "$project_dir"; then
        echo "Error: Failed to change to project directory '$project_dir'." >&2
        return 1
    fi

    if [[ "$SPIN_INSTALL_DEPENDENCIES" == "true" ]]; then
        echo "${BLUE}Installing Node dependencies with ${javascript_package_manager}...${RESET}"
        if ! $COMPOSE_CMD run --no-deps --rm --remove-orphans node ${javascript_package_manager} install; then
            echo "${BOLD}${RED}Error: Failed to install node dependencies.${RESET}" >&2
            return 1
        fi
        echo "Node dependencies installed successfully."
    fi
}

configure_vite() {
    # Check if vite.config.js or vite.config.ts exists
    if [ -f "$project_dir/vite.config.js" ]; then
        vite_config="$project_dir/vite.config.js"
    elif [ -f "$project_dir/vite.config.ts" ]; then
        vite_config="$project_dir/vite.config.ts"
    else
        echo "Warning: vite.config.js or vite.config.ts not found. Skipping Vite configuration."
        return
    fi

    echo "Configuring Vite for Docker..."
    
    if ! grep -q "server:" "$vite_config"; then
        if grep -q "plugins: \[" "$vite_config"; then
             line_in_file --action replace --file "$vite_config" "plugins: \[" "server: { host: '0.0.0.0', hmr: { host: 'localhost' } }, plugins: ["
        else
            echo "Could not find 'plugins: [' in $vite_config. Manual Vite configuration may be required."
        fi
    else
        echo "Vite server configuration already detected (or 'server:' keyword found). Skipping auto-injection to avoid conflicts."
    fi
}

process_selections() { 
    [[ $mysql ]] && configure_mysql
    [[ $queue ]] && configure_queue
    echo "Services configured."
}



select_features() {
    while true; do
        clear
        echo "${BOLD}${YELLOW}Select which Laravel features you'd like to use:${RESET}"
        echo -e "${queue:+$BOLD$BLUE}1) Queues (database driver)${RESET}"
        echo "Press 1 to select/deselect."
        echo "Press ${BOLD}${BLUE}ENTER${RESET} to continue or skip."

        read -s -r -n 1 key
        case $key in
            1) [[ $queue ]] && queue="" || queue="1" ;;
            '') break ;;
        esac
    done
}





select_php_extensions() {
    clear
    echo "${BOLD}${YELLOW}What PHP extensions would you like to include?${RESET}"
    echo ""
    echo "${BLUE}Default extensions:${RESET}"
    echo "ctype, curl, dom, fileinfo, filter, hash, mbstring, mysqli,"
    echo "opcache, openssl, pcntl, pcre, pdo_mysql, pdo_pgsql, redis,"
    echo "session, tokenizer, xml, zip"
    echo ""
    echo "${BLUE}See available extensions:${RESET}"
    echo "https://serversideup.net/docker-php/available-extensions"
    echo ""
    echo "Enter additional extensions as a comma-separated list (no spaces).${RESET}"
    echo "Example: gd,imagick,intl"
    echo ""
    echo "${BOLD}${YELLOW}Enter comma separated extensions below or press ${BOLD}${BLUE}ENTER${RESET} ${BOLD}${YELLOW}to use default extensions.${RESET}"
    read -r extensions_input

    # Remove spaces and split into array
    IFS=',' read -r -a php_extensions <<< "${extensions_input// /}"

    # Print selected extensions for confirmation
    while true; do
        if [ ${#php_extensions[@]} -gt 0 ]; then
            clear
            echo "${BOLD}${YELLOW}These extensions names must be supported in the PHP version you selected.${RESET}"
            echo "Learn more here: https://serversideup.net/docker-php/available-extensions"
            echo ""
            echo "${BLUE}PHP Version:${RESET} $SPIN_PHP_VERSION"
            echo "${BLUE}Extensions:${RESET}"
            for extension in "${php_extensions[@]}"; do
                echo "- $extension"
            done
            echo ""
            echo "${BOLD}${YELLOW}Are these selections correct?${RESET}"
            echo "Press ${BOLD}${BLUE}ENTER${RESET} to continue or ${BOLD}${BLUE}any other key${RESET} to go back and change selections."
            read -n 1 -s -r key
            echo

            if [[ $key == "" ]]; then
                echo "${GREEN}Continuing with selected extensions...${RESET}"
                break
            else
                echo "${YELLOW}Returning to extension selection...${RESET}"
                select_php_extensions
                return
            fi
        else
            break
        fi
    done
}

set_colors() {
    if [[ -t 1 ]]; then
        RAINBOW="
            $(printf '\033[38;5;196m')
            $(printf '\033[38;5;202m')
            $(printf '\033[38;5;226m')
            $(printf '\033[38;5;082m')
            "
        RED=$(printf '\033[31m')
        GREEN=$(printf '\033[32m')
        YELLOW=$(printf '\033[33m')
        BLUE=$(printf '\033[34m')
        DIM=$(printf '\033[2m')
        BOLD=$(printf '\033[1m')
        RESET=$(printf '\033[m')
    else
        RAINBOW=""
        RED=""
        GREEN=""
        YELLOW=""
        BLUE=""
        DIM=""
        BOLD=""
        RESET=""
    fi
}



###############################################
# Main
###############################################

set_colors
select_php_extensions
select_features

# Clean up the screen before moving forward
clear

# Set PHP Version of Project
line_in_file --action replace --file "$project_dir/$php_dockerfile" "FROM serversideup" "FROM ${SPIN_PHP_DOCKER_BASE_IMAGE} AS base"

# Add PHP Extensions if available
if [ ${#php_extensions[@]} -gt 0 ]; then
    add_php_extensions
fi

# Install Composer dependencies
if [[ "$SPIN_INSTALL_DEPENDENCIES" == "true" ]]; then
    docker pull "$SPIN_PHP_DOCKER_INSTALLER_IMAGE"

    if [[ "$SPIN_ACTION" == "init" ]]; then
        echo "Re-installing composer dependencies..."
        docker compose run --rm --no-deps --build \
            -e COMPOSER_CACHE_DIR=/dev/null \
            -e "SHOW_WELCOME_MESSAGE=false" \
            php \
            composer install

        echo "Installing Spin..."
        docker compose run --rm --build --no-deps --remove-orphans \
            -e COMPOSER_CACHE_DIR=/dev/null \
            -e "SHOW_WELCOME_MESSAGE=false" \
                php \
                composer require serversideup/spin --dev
    else
        echo "Installing Spin..."
        docker run --rm \
            -v "$project_dir:/var/www/html" \
            --user "${SPIN_USER_ID}:${SPIN_GROUP_ID}" \
            -e COMPOSER_CACHE_DIR=/dev/null \
            -e "SHOW_WELCOME_MESSAGE=false" \
            "$SPIN_PHP_DOCKER_INSTALLER_IMAGE" \
            composer require serversideup/spin --dev
    fi
fi

# Process the user selections
process_selections



# Configure Server Contact
line_in_file --action exact --ignore-missing --file "$project_dir/.infrastructure/conf/traefik/prod/traefik.yml" "changeme@example.com" "$SERVER_CONTACT"
line_in_file --action exact --ignore-missing --file "$project_dir/.spin.yml" "changeme@example.com" "$SERVER_CONTACT"

if [[ "$SPIN_INSTALL_DEPENDENCIES" == "true" ]]; then
    install_node_dependencies
    configure_vite
fi

if [[ ! -d "$project_dir/.git" ]]; then
    initialize_git_repository
fi

# Export actions so it's available to the main Spin script
export SPIN_USER_TODOS