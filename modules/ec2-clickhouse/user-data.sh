#!/bin/bash
set -e

# Update system
apt-get update
apt-get upgrade -y

# Install ClickHouse
apt-get install -y apt-transport-https ca-certificates dirmngr
apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 8919F6BD2B48D754

echo "deb https://packages.clickhouse.com/deb stable main" | tee /etc/apt/sources.list.d/clickhouse.list
apt-get update

DEBIAN_FRONTEND=noninteractive apt-get install -y clickhouse-server clickhouse-client

# Format and mount data volume if not already mounted
if ! mountpoint -q /var/lib/clickhouse; then
    # Check if volume is already formatted
    if ! blkid ${device_name}; then
        mkfs.ext4 ${device_name}
    fi

    # Create mount point
    mkdir -p /var/lib/clickhouse

    # Mount volume
    mount ${device_name} /var/lib/clickhouse

    # Add to fstab for persistence
    UUID=$(blkid -s UUID -o value ${device_name})
    echo "UUID=$UUID /var/lib/clickhouse ext4 defaults,nofail 0 2" >> /etc/fstab

    # Set proper permissions
    chown -R clickhouse:clickhouse /var/lib/clickhouse
fi

# Configure ClickHouse to listen on all interfaces
cat > /etc/clickhouse-server/config.d/network.xml <<EOF
<clickhouse>
    <listen_host>0.0.0.0</listen_host>
    <http_port>8123</http_port>
    <tcp_port>9000</tcp_port>
    <interserver_http_port>9009</interserver_http_port>
</clickhouse>
EOF

# Configure ClickHouse users
cat > /etc/clickhouse-server/users.d/custom.xml <<EOF
<clickhouse>
    <profiles>
        <default>
            <max_memory_usage>10000000000</max_memory_usage>
            <use_uncompressed_cache>0</use_uncompressed_cache>
            <load_balancing>random</load_balancing>
        </default>
    </profiles>
    <users>
        <default>
            <password></password>
            <networks>
                <ip>::/0</ip>
            </networks>
            <profile>default</profile>
            <quota>default</quota>
        </default>
    </users>
    <quotas>
        <default>
            <interval>
                <duration>3600</duration>
                <queries>0</queries>
                <errors>0</errors>
                <result_rows>0</result_rows>
                <read_rows>0</read_rows>
                <execution_time>0</execution_time>
            </interval>
        </default>
    </quotas>
</clickhouse>
EOF

# Enable and start ClickHouse
systemctl enable clickhouse-server
systemctl start clickhouse-server

# Wait for ClickHouse to be ready
sleep 10

# Create database for Jaeger
clickhouse-client --query "CREATE DATABASE IF NOT EXISTS jaeger"

# Install CloudWatch agent (optional but recommended)
wget https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb
dpkg -i -E ./amazon-cloudwatch-agent.deb
rm amazon-cloudwatch-agent.deb

echo "ClickHouse installation completed successfully"
