#!/bin/bash

# Prompt for destination directory
read -p "Enter the destination directory: " DESTINATION

# Prompt for Odoo version tag
echo "Select Odoo version tag 16,17 or 18:"
select TAG in 16 17 18; do
  case $TAG in
    16|17|18) break ;;
    *) echo "Invalid option. Please select 16, 17, or 18." ;;
  esac
done

# Prompt for ports
read -p "Enter the Odoo port (default 10016): " PORT
PORT=${PORT:-10016}  # Default to 10016 if no input
read -p "Enter the live chat port (default 20016): " CHAT
CHAT=${CHAT:-20016}  # Default to 20016 if no input

# Clone Odoo directory
git clone --depth=1 --branch odoo-$TAG https://github.com/asierNebiyou/odoo-docker-compose $DESTINATION
rm -rf $DESTINATION/.git

# Create PostgreSQL directory
mkdir -p $DESTINATION/postgresql

# Change ownership to current user and set restrictive permissions for security
sudo chown -R $USER:$USER $DESTINATION
sudo chmod -R 700 $DESTINATION  # Only the user has access

# Check if running on macOS
if [[ "$OSTYPE" == "darwin"* ]]; then
  echo "Running on macOS. Skipping inotify configuration."
else
  # System configuration
  if grep -qF "fs.inotify.max_user_watches" /etc/sysctl.conf; then
    echo $(grep -F "fs.inotify.max_user_watches" /etc/sysctl.conf)
  else
    echo "fs.inotify.max_user_watches = 524288" | sudo tee -a /etc/sysctl.conf
  fi
  sudo sysctl -p
fi

# Set ports in docker-compose.yml
# Update docker-compose configuration
if [[ "$OSTYPE" == "darwin"* ]]; then
  # macOS sed syntax
  sed -i '' 's/10016/'$PORT'/g' $DESTINATION/docker-compose.yml
  sed -i '' 's/20016/'$CHAT'/g' $DESTINATION/docker-compose.yml
else
  # Linux sed syntax
  sed -i 's/10016/'$PORT'/g' $DESTINATION/docker-compose.yml
  sed -i 's/20016/'$CHAT'/g' $DESTINATION/docker-compose.yml
fi

# Set file and directory permissions after installation
find $DESTINATION -type f -exec chmod 644 {} \;
find $DESTINATION -type d -exec chmod 755 {} \;

# Run Odoo
docker-compose -f $DESTINATION/docker-compose.yml up -d

echo "Odoo started at http://localhost:$PORT | Master Password: asier | Live chat port: $CHAT"
