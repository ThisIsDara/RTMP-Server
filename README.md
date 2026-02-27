# MediaMTX RTMP Server Setup

Automated shell script to download, install, and configure MediaMTX (RTMP/HLS server).

## Features

- Automatic architecture detection (amd64, arm64, armv7)
- Downloads latest MediaMTX release from GitHub
- Configures RTMP, HLS, RTSP, WebRTC, and SRT servers
- Opens required firewall ports
- Creates systemd service for auto-start on boot

## Requirements

- Ubuntu/Debian or similar Linux distribution
- Root or sudo access
- wget

## Quick Start

```bash
chmod +x rtmp-setup.sh
sudo ./rtmp-setup.sh
```

## Ports Used

| Service | Port |
|---------|------|
| RTMP | 1935 |
| HLS | 8888 |
| RTSP | 8554 |
| WebRTC | 8889 |
| WebRTC UDP | 8189 |
| SRT | 8890 |

## Usage

### Connection URLs

After installation, use these URLs:

**Publish stream (OBS, ffmpeg, etc):**
```
rtmp://<server-ip>/<stream-key>
```

**Play HLS stream:**
```
http://<server-ip>:8888/<stream-key>/index.m3u8
```

**Play via RTSP:**
```
rtsp://<server-ip>:8554/<stream-key>
```

### Management

```bash
# View logs
journalctl -u mediamtx -f

# Restart service
sudo systemctl restart mediamtx

# Stop service
sudo systemctl stop mediamtx

# Edit configuration
sudo nano /etc/mediamtx/mediamtx.yml
```

## Configuration

Config file is located at `/etc/mediamtx/mediamtx.yml`. Edit this file to:
- Enable/disable protocols
- Set up authentication
- Configure recording
- Adjust HLS settings

## Uninstall

```bash
sudo systemctl stop mediamtx
sudo systemctl disable mediamtx
sudo rm /etc/systemd/system/mediamtx.service
sudo rm /usr/local/bin/mediamtx
sudo rm -rf /etc/mediamtx
```
