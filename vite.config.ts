import { defineConfig } from "vite";
import react from "@vitejs/plugin-react-swc";
import path from "path";
import { componentTagger } from "lovable-tagger";

// https://vitejs.dev/config/
// Nota: se removió vite-plugin-pwa porque el service worker viejo dejaba
// versiones obsoletas pegadas en Safari iOS (redirecciones incorrectas en
// /pedidos). public/sw.js ahora es un kill-switch que se auto-desregistra y
// limpia cachés viejos. La instalación en home screen sigue funcionando vía
// public/manifest.webmanifest.
export default defineConfig(({ mode }) => ({
  server: {
    host: "::",
    port: 8080,
  },
  plugins: [
    react(),
    mode === "development" && componentTagger(),
  ].filter(Boolean),
  resolve: {
    alias: {
      "@": path.resolve(__dirname, "./src"),
    },
  },
}));
