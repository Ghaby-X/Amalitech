#!/bin/bash
#
# setup_environment.sh
# Automates creation of a standard project folder structure
# (logs/, configs/, scripts/) with sample files and permissions.

# exit on failure
set -e

make_dir() {
    local dir_name="$1"
    if [ -d "$dir_name" ]; then
        echo "Directory already exists: $dir_name"
    else
        mkdir -p "$dir_name"
        echo "Created directory: $dir_name"
    fi
}

echo "Setting up DevOps environment"

# Create directories
make_dir "logs"
make_dir "configs"
make_dir "scripts"

# Create files with sample content
echo "System log initialized." > logs/system.log
echo "app_name=DemoApp" > configs/app.conf

cat > scripts/backup.sh << 'EOF'
#!/bin/bash
echo "Backup script placeholder"
EOF

echo "Files created: logs/system.log, configs/app.conf, scripts/backup.sh"

# Modify permissions
chmod 644 logs/system.log
chmod 444 configs/app.conf
chmod 755 scripts/backup.sh

echo "Permissions set: logs/system.log (644), configs/app.conf (444), scripts/backup.sh (755)"

# Display directory structure and permissions
echo ""
echo "Directory structure"
if command -v tree > /dev/null 2>&1; then
    tree .
else
    echo "'tree' command not found. Failed to print out Directory structure"
fi

echo ""
echo "Permissions overview"
ls -lR

echo ""
echo "Setup complete"
