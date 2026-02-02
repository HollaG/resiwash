# ResiWash

ResiWash is a smart laundry monitoring system designed for residential colleges and shared facilities. The system tracks washing machine and dryer availability in real-time, allowing users to check machine status remotely before making a trip to the laundry room.

## Overview

ResiWash addresses the common problem of finding all laundry machines occupied after walking to the laundry room. The system uses light sensors to monitor the indicator lights on washing machines and dryers, providing real-time status updates through a web application accessible from any device.

### Features

- **Real-time status tracking** for all washers and dryers across multiple locations
- **Five distinct machine states**: Available, In Use, Finishing, Has Issues, and Unknown
- **Intelligent sensor detection** that distinguishes between running and finishing cycles
- **Responsive web interface** accessible from mobile devices and computers
- **Admin dashboard** for managing locations, rooms, and machine configurations
- **Stabilization algorithm** to prevent false status changes from flickering lights

## How It Works

The system employs light-dependent resistor (LDR) sensors mounted on washing machines and dryers to monitor their indicator lights. These sensors continuously measure light levels to determine machine availability and status.

### Sensor Configuration

Each machine is equipped with **two light sensors**:
- **Sensor 1**: Monitors the primary indicator light (machine running)
- **Sensor 2**: Monitors the secondary indicator light (cycle completion)

The sensors transmit readings every 5 seconds to an ESP32 microcontroller, which forwards the data to the backend API via WiFi. Users can then view the status through the web application.

### Status Detection Logic

The system uses different detection patterns for washers and dryers:

**Washing Machines:**
- Sensor 1 active only → Machine is in use
- Both sensors active → Cycle finishing
- No sensors active → Machine available

**Dryers:**
- Sensor 1 active → Machine is in use
- Sensor 2 active → Cycle complete, ready to unload
- No sensors active → Machine available

### Stabilization Mechanism

To prevent false status changes caused by flickering lights or temporary sensor fluctuations, the system implements a stabilization algorithm. A status change is only confirmed after **three consecutive identical readings**, requiring approximately 15 seconds of consistent data before updating the machine status in the database.

## Technology Stack

- **Backend**: Node.js, Express, TypeScript, TypeORM, PostgreSQL
- **Frontend**: React, TypeScript, Vite, Mantine UI
- **Hardware**: ESP32 microcontroller, ATtiny414, LDR sensors
- **Authentication**: Firebase (for administrative functions)

## Getting Started

### Prerequisites

- Node.js 18 or higher with npm
- PostgreSQL 12 or higher
- Firebase account (free tier is sufficient)
- PlatformIO (required only for hardware development)

### Backend Setup

1. **Install dependencies:**
   ```bash
   cd api
   npm install
   ```

2. **Initialize the database:**
   ```bash
   createdb resiwash
   ```

3. **Configure environment variables** by creating `api/.env`:
   ```env
   DB_NAME=resiwash
   DB_USER=postgres
   DB_PASSWORD=your_password
   DB_HOST=localhost
   DB_PORT=5432
   SESSION_KEY=RANDOM_STRING
   ```

4. **Configure Firebase authentication:**
   - Download your `service-account.json` file from the Firebase Console
   - Place the file in the `api/` directory

5. **Start the development server:**
   ```bash
   npm run dev
   ```

   The API will be accessible at `http://localhost:3000`

### Frontend Setup

1. **Install dependencies:**
   ```bash
   cd website-simple
   npm install
   ```

2. **Configure Firebase** by creating `website-simple/.env`:
   ```env
   VITE_FIREBASE_API_KEY=your_api_key
   VITE_FIREBASE_AUTH_DOMAIN=your_project.firebaseapp.com
   VITE_FIREBASE_PROJECT_ID=your_project_id
   VITE_FIREBASE_STORAGE_BUCKET=your_project.appspot.com
   VITE_FIREBASE_MESSAGING_SENDER_ID=your_sender_id
   VITE_FIREBASE_APP_ID=your_app_id
   ```

3. **Start the development server:**
   ```bash
   npm run dev
   ```

   The web application will be available at `http://localhost:5173`

### Hardware Setup (Optional)

For those interested in deploying the physical sensor system:

1. **Configure the ATtiny414 sensor board:**
   - Connect two LDR sensors to analog pins 7 and 6
   - Attach a potentiometer to pin 0 for threshold calibration
   - Establish serial connection to ESP32 using pins 5 (TX) and 4 (RX)

2. **Configure the ESP32 microcontroller:**
   - Update WiFi credentials in `server/server.ino`
   - Set the API endpoint URL to match your deployment
   - Upload firmware using PlatformIO: `pio run --target upload`

3. **Calibration procedure:**
   - Mount sensors over the machine indicator lights
   - Adjust the potentiometer until the onboard LEDs accurately reflect light state changes
   - Optimal threshold values typically range from 100-150 (on a scale of 0-250)

## Project Structure

```
resiwash/
├── api/              # Backend (Node.js + Express + PostgreSQL)
├── website-simple/   # Frontend (React + TypeScript)
├── server/           # ESP32 firmware (sends data to API)
├── client/           # NRF52840 firmware (BLE variant)
└── attiny/           # ATtiny414 firmware (reads light sensors)
```

## API Endpoints

The API is accessible at `http://localhost:3000/api/v2` and provides the following endpoints:

- `GET /areas` - Retrieve all registered locations
- `GET /rooms?areaId=:id` - Retrieve rooms within a specific location
- `GET /machines?roomId=:id` - Retrieve machines within a specific room
- `GET /machines/:id` - Retrieve detailed status of a specific machine
- `POST /events/bulk` - Submit sensor data (used by ESP32 devices)

Administrative operations (create, update, delete) require Firebase authentication tokens.

## Production Deployment

**Backend:**
```bash
cd api
npm run build
npm start
```

**Frontend:**
```bash
cd website-simple
npm run build
# Deploy the generated dist/ folder to your preferred static hosting service
```

## Contributing

Contributions to ResiWash are welcome. To contribute:

1. Fork the repository
2. Create a feature branch for your changes
3. Submit a pull request with a clear description of your improvements

## Support

If you encounter issues or have suggestions for improvements, please open an issue on the GitHub repository.
