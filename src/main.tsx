// PRIMERO: lo que los teléfonos viejos no traen. Va antes que React porque si
// falta, la pantalla que lo usa se cae antes de pintarse.
import "./lib/compat";

import { createRoot } from "react-dom/client";
import App from "./App.tsx";
import "./index.css";

createRoot(document.getElementById("root")!).render(<App />);
