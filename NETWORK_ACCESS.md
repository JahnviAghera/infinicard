# Network Access Configuration Guide

This guide explains how to access your Infinicard backend API from different devices.

## 🔧 Current Configuration

### Backend Server
- **Port**: 3000
- **Listen Address**: 0.0.0.0 (all network interfaces)
- **Status**: ✅ Ready to accept connections from any device

### Your Computer's IP Addresses
- **Local Network**: `192.168.1.16` (WiFi/Ethernet)
- **Docker Network**: `172.26.112.1` (internal)

---

## 📱 Access from Different Devices

### 1️⃣ Android Emulator (AVD)
**Use**: `10.0.2.2:3000`

```dart
// lib/services/api_service.dart
static const String baseUrl = 'http://10.0.2.2:3000/api';
```

**Why**: Android emulators use special IP `10.0.2.2` to reach the host machine's localhost.

---

### 2️⃣ Physical Android/iOS Device (Same WiFi)
**Use**: `192.168.1.16:3000`

```dart
// lib/services/api_service.dart
static const String baseUrl = 'http://192.168.1.16:3000/api';
```

**Requirements**:
- ✅ Phone connected to same WiFi network
- ✅ Windows Firewall allows port 3000 (see below)
- ✅ Backend server running

---

### 3️⃣ Browser/Postman (Same Computer)
**Use**: `localhost:3000` or `127.0.0.1:3000`

```
GET http://localhost:3000/health
GET http://localhost:3000/api/auth/profile
```

---

### 4️⃣ Browser/Postman (Other Computers on Network)
**Use**: `192.168.1.16:3000`

```
GET http://192.168.1.16:3000/health
```

---

## 🔥 Windows Firewall Configuration

To allow physical devices to connect, you need to allow incoming connections on port 3000:

### Option A: Quick Command (Administrator)
```cmd
netsh advfirewall firewall add rule name="Infinicard API" dir=in action=allow protocol=TCP localport=3000
```

### Option B: GUI Method
1. Open **Windows Defender Firewall with Advanced Security**
2. Click **Inbound Rules** → **New Rule**
3. Select **Port** → Click **Next**
4. Select **TCP** → Enter `3000` → Click **Next**
5. Select **Allow the connection** → Click **Next**
6. Check all profiles (Domain, Private, Public) → Click **Next**
7. Name: `Infinicard API Server` → Click **Finish**

---

## 🧪 Testing Connectivity

### Test Backend Health
From your **phone's browser** or **another computer**:
```
http://192.168.1.16:3000/health
```

**Expected Response**:
```json
{
  "status": "ok",
  "message": "Infinicard API is running",
  "timestamp": "2024-01-15T10:30:00.000Z",
  "database": "connected"
}
```

### Test from Flutter App
1. Update `lib/services/api_service.dart` with appropriate IP
2. Hot restart app: Press **R** in terminal or **Ctrl+\**
3. Try to register/login
4. Check if connection works

---

## 🌐 Making It Accessible from Internet (Production)

For **true public access** like "everyone can use it", you need:

### Option 1: Cloud Hosting (Recommended)
- **Deploy to**: Railway, Render, Heroku, DigitalOcean, AWS
- **Get**: Real domain (e.g., `api.infinicard.com`)
- **Benefits**: HTTPS, reliability, scalability

### Option 2: Home Network Tunneling
- **Use**: ngrok, localtunnel, Cloudflare Tunnel
- **Command**: `ngrok http 3000`
- **Get**: Public URL like `https://abc123.ngrok.io`
- **Note**: URL changes every restart (free tier)

### Option 3: Port Forwarding (Not Recommended)
- Configure router to forward port 3000
- Use dynamic DNS (No-IP, DuckDNS)
- **Security Risk**: Exposing home IP publicly

---

## 🔄 Switching Between Configurations

### For Development
Create environment-based configuration:

```dart
// lib/config/environment.dart
class Environment {
  static const String dev = 'development';
  static const String prod = 'production';
  
  static const String current = dev; // Change as needed
  
  static String get baseUrl {
    switch (current) {
      case dev:
        return 'http://10.0.2.2:3000/api'; // Emulator
      case prod:
        return 'https://api.infinicard.com/api'; // Production
      default:
        return 'http://localhost:3000/api';
    }
  }
}
```

Then use in `api_service.dart`:
```dart
static final String baseUrl = Environment.baseUrl;
```

---

## 🎯 Current Status

| Device Type | IP Address | Status |
|------------|------------|--------|
| **Android Emulator** | `10.0.2.2:3000` | ✅ Configured |
| **Physical Device (WiFi)** | `192.168.1.16:3000` | ⚠️ Requires firewall rule |
| **Same Computer** | `localhost:3000` | ✅ Working |
| **Other Computers** | `192.168.1.16:3000` | ⚠️ Requires firewall rule |
| **Internet (Public)** | N/A | ❌ Not configured |

---

## 📝 Quick Reference

```yaml
# Emulator Testing
baseUrl: 'http://10.0.2.2:3000/api'

# Physical Device Testing (Same WiFi)
baseUrl: 'http://192.168.1.16:3000/api'

# Production Deployment
baseUrl: 'https://api.infinicard.com/api'
```

---

## 🚨 Important Notes

1. **IP May Change**: Your local IP (192.168.1.16) can change if DHCP lease expires. Use router's DHCP reservation for static IP.

2. **Emulator vs Real Device**: Don't forget to switch baseUrl when moving between emulator and physical device testing.

3. **Security**: Never use `0.0.0.0` or `*` CORS in production. Restrict to specific domains.

4. **HTTPS**: Physical devices will show "Not Secure" warnings. Use HTTPS in production.

5. **Network Reliability**: Local network testing can have delays/dropouts. Test on stable WiFi.

---

## 🔧 Troubleshooting

### "Connection Refused" on Physical Device
1. ✅ Check backend is running: `http://localhost:3000/health`
2. ✅ Verify firewall rule exists
3. ✅ Confirm both devices on same WiFi
4. ✅ Ping test: `ping 192.168.1.16` from phone terminal app
5. ✅ Try browser first before Flutter app

### "Network Error" in Flutter
1. ✅ Check baseUrl matches your testing device
2. ✅ Hot restart app after changing baseUrl
3. ✅ Clear app data/reinstall if tokens corrupted
4. ✅ Enable verbose logging in api_service.dart

### "Timeout" Errors
1. ✅ Increase timeout in http requests
2. ✅ Check router firewall settings
3. ✅ Disable VPN/proxy on phone
4. ✅ Test with mobile data hotspot

---

## 📞 Next Steps

1. **Now**: Test on Android emulator with `10.0.2.2`
2. **Next**: Add firewall rule and test on physical device with `192.168.1.16`
3. **Later**: Deploy to cloud for public access

Happy coding! 🚀
