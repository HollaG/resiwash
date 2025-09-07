import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";

// https://vite.dev/config/
export default defineConfig(() => ({
  plugins: [react()],
  // Vite automatically loads .env files based on mode
  // .env.development for dev mode, .env.production for build mode
}));
