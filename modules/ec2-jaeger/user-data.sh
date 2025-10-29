#!/bin/bash
set -e

# Update system
apt-get update
apt-get upgrade -y

# Install Docker
apt-get install -y ca-certificates curl gnupg lsb-release

# Add Docker's official GPG key
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

# Set up Docker repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker Engine
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Start and enable Docker
systemctl start docker
systemctl enable docker

# Create Jaeger configuration directory
mkdir -p /opt/jaeger

# Create docker-compose file for Jaeger with ClickHouse backend
cat > /opt/jaeger/docker-compose.yml <<EOF
version: '3.8'

services:
  jaeger-collector:
    image: jaegertracing/jaeger-collector:1.52
    container_name: jaeger-collector
    restart: unless-stopped
    ports:
      - "14250:14250"  # gRPC
      - "14268:14268"  # HTTP
      - "14269:14269"  # Admin port
      - "9411:9411"    # Zipkin compatible endpoint
    environment:
      - SPAN_STORAGE_TYPE=grpc-plugin
      - GRPC_STORAGE_SERVER=jaeger-clickhouse:9000
      - GRPC_STORAGE_TLS=false
      - COLLECTOR_ZIPKIN_HOST_PORT=:9411
      - COLLECTOR_OTLP_ENABLED=true
    depends_on:
      - jaeger-clickhouse
    networks:
      - jaeger-network

  jaeger-query:
    image: jaegertracing/jaeger-query:1.52
    container_name: jaeger-query
    restart: unless-stopped
    ports:
      - "16686:16686"  # Jaeger UI
      - "16687:16687"  # Admin port
    environment:
      - SPAN_STORAGE_TYPE=grpc-plugin
      - GRPC_STORAGE_SERVER=jaeger-clickhouse:9000
      - GRPC_STORAGE_TLS=false
      - QUERY_BASE_PATH=/jaeger
    depends_on:
      - jaeger-clickhouse
    networks:
      - jaeger-network

  jaeger-clickhouse:
    image: ghcr.io/jaegertracing/jaeger-clickhouse:latest
    container_name: jaeger-clickhouse-plugin
    restart: unless-stopped
    environment:
      - CH_HOST=${clickhouse_host}
      - CH_PORT=${clickhouse_http_port}
      - CH_DATABASE=jaeger
      - CH_USERNAME=default
      - CH_PASSWORD=
    networks:
      - jaeger-network

networks:
  jaeger-network:
    driver: bridge
EOF

# Start Jaeger services
cd /opt/jaeger
docker compose up -d

# Wait for services to be ready
sleep 15

# Create initialization script for ClickHouse schema
cat > /opt/jaeger/init-clickhouse.sh <<'INIT_SCRIPT'
#!/bin/bash

# Wait for ClickHouse to be ready
echo "Waiting for ClickHouse to be ready..."
until docker exec jaeger-clickhouse-plugin wget -q --spider http://${clickhouse_host}:${clickhouse_http_port}/ping; do
  echo "ClickHouse is unavailable - sleeping"
  sleep 2
done

echo "ClickHouse is up - initializing schema"

# The jaeger-clickhouse plugin will automatically create the necessary tables
# But we can verify the database exists
docker exec jaeger-clickhouse-plugin wget -qO- "http://${clickhouse_host}:${clickhouse_http_port}/?query=SHOW+DATABASES" | grep -q jaeger && echo "Jaeger database exists" || echo "Jaeger database not found"

echo "Initialization complete"
INIT_SCRIPT

chmod +x /opt/jaeger/init-clickhouse.sh
/opt/jaeger/init-clickhouse.sh

# Install CloudWatch agent
wget https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb
dpkg -i -E ./amazon-cloudwatch-agent.deb
rm amazon-cloudwatch-agent.deb

# Create systemd service to ensure Jaeger starts on boot
cat > /etc/systemd/system/jaeger.service <<EOF
[Unit]
Description=Jaeger Tracing
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/opt/jaeger
ExecStart=/usr/bin/docker compose up -d
ExecStop=/usr/bin/docker compose down

[Install]
WantedBy=multi-user.target
EOF

systemctl enable jaeger.service

echo "Jaeger installation completed successfully"
echo "Jaeger UI available at: http://$(hostname -I | awk '{print $1}'):16686"
echo "Jaeger Collector gRPC: $(hostname -I | awk '{print $1}'):14250"
echo "Jaeger Collector HTTP: $(hostname -I | awk '{print $1}'):14268"
