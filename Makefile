# Makefile for WordPress Duplicator Docker Setup

WORDPRESS_URL ?= http://localhost
COOKIE_FILE ?= /tmp/wp-cookies.txt

.PHONY: help up down build reset logs shell db reset-password
.DEFAULT_GOAL := help

help: ## Show this help message
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

up: ## Bring the environment up in the background
	docker compose up -d

down: ## Bring the environment down
	docker compose down

build: ## Rebuild the containers (useful if you change the Dockerfile or scripts)
	docker compose up -d --build

reset: down ## Wipe local data and force a fresh extraction from the zip archive
	@echo "Wiping local database and web files to force a fresh restore..."
	sudo rm -rf wp-mysql/* wp-mysql/.??*
	sudo rm -rf wp-app/* wp-app/.??*
	docker compose up -d --build
	@echo "Reset complete. Containers are building/extracting."

logs: ## Follow the logs of the duplicate container to watch the extraction
	docker compose logs -f duplicate

shell: ## Open a bash shell inside the running web container
	docker compose exec duplicate bash

db: ## Open a MySQL prompt directly into the database
	docker compose exec db mysql -u root -ppassword wordpress

reset-password: ## List available users and interactively reset a password
	@echo "--- Available WordPress Users ---"
	@docker compose exec db mysql -u root -ppassword wordpress -e "SELECT user_login FROM wp_users;"
	@echo "---------------------------------"
	@read -p "Enter the username you want to reset: " wp_user; \
	read -p "Enter the new password: " wp_pass; \
	docker compose exec db mysql -u root -ppassword wordpress -e "UPDATE wp_users SET user_pass = MD5('$$wp_pass') WHERE user_login = '$$wp_user';"; \
	echo "\n✅ Password successfully updated for $$wp_user! You can now log in."

export-xml: ## Export WordPress content to an XML file via curl
	@echo "--- Export WordPress XML ---"
	@read -p "Enter WordPress admin username: " wp_user; \
	read -s -p "Enter WordPress admin password: " wp_pass; \
	echo "\nLogging into WordPress and exporting XML..."; \
	curl -v -c $(COOKIE_FILE) \
		-d "log=$$wp_user" \
		-d "pwd=$$wp_pass" \
		"$(WORDPRESS_URL)/wp-login.php" > /dev/null && \
	curl -v -b $(COOKIE_FILE) \
		-J -O \
		"$(WORDPRESS_URL)/wp-admin/export.php?download=true&content=all"; \
	echo "✅ Export complete! File saved in the current directory."