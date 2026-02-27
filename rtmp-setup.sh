#!/bin/bash

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  MediaMTX RTMP Server Setup${NC}"
echo -e "${GREEN}========================================${NC}"

if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}Error: This script must be run as root${NC}"
   exit 1
fi

if ! command -v wget &> /dev/null; then
   echo -e "${YELLOW}Installing wget...${NC}"
   apt-get update && apt-get install -y wget
fi

ARCH=$(uname -m)
case "$ARCH" in
    x86_64) ARCH_NAME="amd64" ;;
    aarch64) ARCH_NAME="arm64" ;;
    armv7l) ARCH_NAME="armv7" ;;
    *) echo -e "${RED}Unsupported architecture: $ARCH${NC}"; exit 1 ;;
esac

echo -e "${YELLOW}Detected architecture: $ARCH ($ARCH_NAME)${NC}"

echo -e "${YELLOW}Fetching latest MediaMTX version...${NC}"
LATEST_VERSION=$(curl -sL "https://api.github.com/repos/bluenviron/mediamtx/releases/latest" | grep -o '"tag_name": "v[^"]*"' | cut -d'"' -f4)
echo -e "${GREEN}Latest version: $LATEST_VERSION${NC}"

FILENAME="mediamtx_v${LATEST_VERSION#v}_linux_${ARCH_NAME}.tar.gz"
DOWNLOAD_URL="https://github.com/bluenviron/mediamtx/releases/download/${LATEST_VERSION}/${FILENAME}"

echo -e "${YELLOW}Downloading MediaMTX...${NC}"
cd /tmp
wget -O "${FILENAME}" "${DOWNLOAD_URL}"

echo -e "${YELLOW}Extracting MediaMTX...${NC}"
tar -xzf "${FILENAME}"
rm -f "${FILENAME}"

echo -e "${YELLOW}Installing MediaMTX binary...${NC}"
mv mediamtx /usr/local/bin/mediamtx
chmod +x /usr/local/bin/mediamtx
ln -sf /usr/local/bin/mediamtx /usr/bin/mediamtx

echo -e "${YELLOW}Creating configuration directory...${NC}"
mkdir -p /etc/mediamtx
mkdir -p ./recordings

echo -e "${YELLOW}Creating MediaMTX configuration...${NC}"
cat > /etc/mediamtx/mediamtx.yml << 'EOF'
###############################################
# Global settings

# Verbosity of the program; available values are "error", "warn", "info", "debug".
logLevel: info
# Destinations of log messages; available values are "stdout", "file" and "syslog".
logDestinations: [stdout]
# When destination is "stdout" or "file", emit logs in structured format (JSONL).
logStructured: false
# When "file" is in logDestinations, this is the file which will receive logs.
logFile: mediamtx.log

# Timeout of read operations.
readTimeout: 10s
# Timeout of write operations.
writeTimeout: 10s
# Size of the queue of outgoing packets.
writeQueueSize: 512
# Maximum size of outgoing UDP payloads.
udpMaxPayloadSize: 1452
# Size of the read buffer of every UDP socket.
udpReadBufferSize: 0

# Command to run when a client connects to the server.
runOnConnect:
# Restart the command if it exits.
runOnConnectRestart: false
# Command to run when a client disconnects from the server.
runOnDisconnect:

###############################################
# Global settings -> Authentication

# Authentication method. Available values are:
# * internal: credentials are stored in the configuration file
# * http: an external HTTP URL is contacted to perform authentication
# * jwt: an external identity server provides authentication through JWTs
authMethod: internal

# Internal authentication.
authInternalUsers:
- user: any
  pass:
  ips: []
  permissions:
  - action: publish
    path:
  - action: read
    path:
  - action: playback
    path:

- user: any
  pass:
  ips: ['127.0.0.1', '::1']
  permissions:
  - action: api
  - action: metrics
  - action: pprof

# HTTP-based authentication.
authHTTPAddress:
authHTTPFingerprint:
authHTTPExclude:
- action: api
- action: metrics
- action: pprof

# JWT-based authentication.
authJWTJWKS:
authJWTJWKSFingerprint:
authJWTClaimKey: mediamtx_permissions
authJWTExclude: []
authJWTInHTTPQuery: true

###############################################
# Global settings -> Control API

api: false
apiAddress: :9997
apiEncryption: false
apiServerKey: server.key
apiServerCert: server.crt
apiAllowOrigins: ['*']
apiTrustedProxies: []

###############################################
# Global settings -> Metrics

metrics: false
metricsAddress: :9998
metricsEncryption: false
metricsServerKey: server.key
metricsServerCert: server.crt
metricsAllowOrigins: ['*']
metricsTrustedProxies: []

###############################################
# Global settings -> PPROF

pprof: false
pprofAddress: :9999
pprofEncryption: false
pprofServerKey: server.key
pprofServerCert: server.crt
pprofAllowOrigins: ['*']
pprofTrustedProxies: []

###############################################
# Global settings -> Playback server

playback: false
playbackAddress: :9996
playbackEncryption: false
playbackServerKey: server.key
playbackServerCert: server.crt
playbackAllowOrigins: ['*']
playbackTrustedProxies: []

###############################################
# Global settings -> RTSP server

rtsp: true
rtspTransports: [udp, multicast, tcp]
rtspEncryption: "no"
rtspAddress: :8554
rtspsAddress: :8322
rtpAddress: :8000
rtcpAddress: :8001
multicastIPRange: 224.1.0.0/16
multicastRTPPort: 8002
multicastRTCPPort: 8003
srtpAddress: :8004
srtcpAddress: :8005
multicastSRTPPort: 8006
multicastSRTCPPort: 8007
rtspServerKey: server.key
rtspServerCert: server.crt
rtspAuthMethods: [basic]

###############################################
# Global settings -> RTMP server

rtmp: true
rtmpEncryption: "no"
rtmpAddress: :1935
rtmpsAddress: :1936
rtmpServerKey: server.key
rtmpServerCert: server.crt

###############################################
# Global settings -> HLS server

hls: true
hlsAddress: :8888
hlsEncryption: false
hlsServerKey: server.key
hlsServerCert: server.crt
hlsAllowOrigins: ['*']
hlsTrustedProxies: []
hlsAlwaysRemux: false
hlsVariant: lowLatency
hlsSegmentCount: 7
hlsSegmentDuration: 1s
hlsPartDuration: 200ms
hlsSegmentMaxSize: 50M
hlsDirectory: ''
hlsMuxerCloseAfter: 60s

###############################################
# Global settings -> WebRTC server

webrtc: true
webrtcAddress: :8889
webrtcEncryption: false
webrtcServerKey: server.key
webrtcServerCert: server.crt
webrtcAllowOrigins: ['*']
webrtcTrustedProxies: []
webrtcLocalUDPAddress: :8189
webrtcLocalTCPAddress: ''
webrtcIPsFromInterfaces: true
webrtcIPsFromInterfacesList: []
webrtcAdditionalHosts: []
webrtcICEServers2: []
webrtcSTUNGatherTimeout: 5s
webrtcHandshakeTimeout: 10s
webrtcTrackGatherTimeout: 2s

###############################################
# Global settings -> SRT server

srt: true
srtAddress: :8890

###############################################
# Default path settings

pathDefaults:

  # Source of the stream. This can be:
  # * publisher -> the stream is provided by a RTSP, RTMP, WebRTC or SRT client
  source: publisher
  sourceFingerprint:
  sourceOnDemand: false
  sourceOnDemandStartTimeout: 10s
  sourceOnDemandCloseAfter: 10s
  maxReaders: 0
  srtReadPassphrase:
  useAbsoluteTimestamp: false

  # Always available
  alwaysAvailable: false
  alwaysAvailableFile: ''
  alwaysAvailableTracks:
    - codec: H264

  # Record
  record: false
  recordPath: ./recordings/%path/%Y-%m-%d_%H-%M-%S-%f
  recordFormat: fmp4
  recordPartDuration: 1s
  recordMaxPartSize: 50M
  recordSegmentDuration: 1h
  recordDeleteAfter: 1d

  # Publisher source
  overridePublisher: true
  srtPublishPassphrase:

  # RTSP source
  rtspTransport: automatic
  rtspAnyPort: false
  rtspRangeType:
  rtspRangeStart:
  rtspUDPSourcePortRange: [10000, 65535]

  # RTP source
  rtpSDP:

  # WebRTC / WHEP source
  whepBearerToken: ''
  whepSTUNGatherTimeout: 5s
  whepHandshakeTimeout: 10s
  whepTrackGatherTimeout: 2s

  # Redirect source
  sourceRedirect:

  # Hooks
  runOnInit:
  runOnInitRestart: false
  runOnDemand:
  runOnDemandRestart: false
  runOnDemandStartTimeout: 10s
  runOnDemandCloseAfter: 10s
  runOnUnDemand:
  runOnReady:
  runOnReadyRestart: false
  runOnNotReady:
  runOnRead:
  runOnReadRestart: false
  runOnUnread:
  runOnRecordSegmentCreate:
  runOnRecordSegmentComplete:

###############################################
# Path settings

paths:
  all_others:
EOF

echo -e "${YELLOW}Creating systemd service...${NC}"
cat > /etc/systemd/system/mediamtx.service << 'EOF'
[Unit]
Description=MediaMTX RTMP/HLS Server
After=network.target

[Service]
Type=simple
WorkingDirectory=/etc/mediamtx
ExecStart=/usr/local/bin/mediamtx /etc/mediamtx/mediamtx.yml
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
if command -v ufw &> /dev/null; then
    ufw allow 1935/tcp comment 'RTMP'
    ufw allow 8888/tcp comment 'HLS'
    ufw allow 8554/tcp comment 'RTSP'
    ufw allow 8889/tcp comment 'WebRTC'
    ufw allow 9997/tcp comment 'MediaMTX API'
    echo -e "${GREEN}UFW rules added${NC}"
elif command -v firewall-cmd &> /dev/null; then
    firewall-cmd --permanent --add-port=1935/tcp
    firewall-cmd --permanent --add-port=8888/tcp
    firewall-cmd --permanent --add-port=8554/tcp
    firewall-cmd --permanent --add-port=8889/tcp
    firewall-cmd --permanent --add-port=9997/tcp
    firewall-cmd --reload
    echo -e "${GREEN}FirewallD rules added${NC}"
elif command -v iptables &> /dev/null; then
    iptables -A INPUT -p tcp --dport 1935 -j ACCEPT
    iptables -A INPUT -p tcp --dport 8888 -j ACCEPT
    iptables -A INPUT -p tcp --dport 8554 -j ACCEPT
    iptables -A INPUT -p tcp --dport 8889 -j ACCEPT
    iptables -A INPUT -p tcp --dport 9997 -j ACCEPT
    echo -e "${GREEN}IPTables rules added (not persistent)${NC}"
else
    echo -e "${YELLOW}No firewall tool detected. Please open ports manually:${NC}"
    echo "  1935 (RTMP), 8888 (HLS), 8554 (RTSP), 8889 (WebRTC), 9997 (API)"
fi

echo -e "${YELLOW}Creating systemd service...${NC}"
cat > /etc/systemd/system/mediamtx.service << 'EOF'
[Unit]
Description=MediaMTX RTMP/HLS Server
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/mediamtx /etc/mediamtx/mediamtx.yml
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

echo -e "${YELLOW}Configuring firewall...${NC}"
if command -v ufw &> /dev/null; then
    ufw allow 1935/tcp comment 'RTMP'
    ufw allow 8888/tcp comment 'HLS'
    ufw allow 8554/tcp comment 'RTSP'
    ufw allow 8889/tcp comment 'WebRTC'
    ufw allow 8890/tcp comment 'SRT'
    ufw allow 8189/udp comment 'WebRTC UDP'
    echo -e "${GREEN}UFW rules added${NC}"
elif command -v firewall-cmd &> /dev/null; then
    firewall-cmd --permanent --add-port=1935/tcp
    firewall-cmd --permanent --add-port=8888/tcp
    firewall-cmd --permanent --add-port=8554/tcp
    firewall-cmd --permanent --add-port=8889/tcp
    firewall-cmd --permanent --add-port=8890/tcp
    firewall-cmd --permanent --add-port=8189/udp
    firewall-cmd --reload
    echo -e "${GREEN}FirewallD rules added${NC}"
elif command -v iptables &> /dev/null; then
    iptables -A INPUT -p tcp --dport 1935 -j ACCEPT
    iptables -A INPUT -p tcp --dport 8888 -j ACCEPT
    iptables -A INPUT -p tcp --dport 8554 -j ACCEPT
    iptables -A INPUT -p tcp --dport 8889 -j ACCEPT
    iptables -A INPUT -p tcp --dport 8890 -j ACCEPT
    iptables -A INPUT -p udp --dport 8189 -j ACCEPT
    echo -e "${GREEN}IPTables rules added (not persistent)${NC}"
else
    echo -e "${YELLOW}No firewall tool detected. Please open ports manually:${NC}"
    echo "  1935 (RTMP), 8888 (HLS), 8554 (RTSP), 8889 (WebRTC), 8890 (SRT), 8189 (WebRTC UDP)"
fi

systemctl daemon-reload

echo -e "${YELLOW}Starting MediaMTX service...${NC}"
systemctl enable mediamtx
systemctl start mediamtx

sleep 2

if systemctl is-active --quiet mediamtx; then
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}  MediaMTX Started Successfully!${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    echo -e "${YELLOW}Service Status:${NC}"
    systemctl status mediamtx --no-pager
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}  Connection URLs${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    echo -e "${YELLOW}RTMP Input (for OBS/Streaming软件):${NC}"
    echo -e "  ${GREEN}rtmp://<your-ip>/<stream-key>${NC}"
    echo ""
    echo -e "${YELLOW}HLS Playback:${NC}"
    echo -e "  ${GREEN}http://<your-ip>:8888/<stream-key>/index.m3u8${NC}"
    echo ""
    echo -e "${YELLOW}API (for management):${NC}"
    echo -e "  ${GREEN}http://<your-ip>:9997/v3/paths/list${NC}"
    echo ""
    echo -e "${YELLOW}Config file:${NC}"
    echo -e "  ${GREEN}/etc/mediamtx/mediamtx.yml${NC}"
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}  Useful Commands${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    echo -e "  View logs:    ${GREEN}journalctl -u mediamtx -f${NC}"
    echo -e "  Stop server:  ${GREEN}systemctl stop mediamtx${NC}"
    echo -e "  Restart:      ${GREEN}systemctl restart mediamtx${NC}"
    echo -e "  Edit config:  ${GREEN}nano /etc/mediamtx/mediamtx.yml${NC}"
    echo ""
else
    echo -e "${RED}Failed to start MediaMTX. Checking logs...${NC}"
    journalctl -u mediamtx -n 20 --no-pager
    exit 1
fi
