const express = require("express");
const path = require("path");
const cors = require("cors");

const juegosRoutes = require("./routes/juegos");
const carritoRoutes = require("./routes/carrito");
const authRoutes = require("./routes/auth");
const usuarioRoutes = require("./routes/usuario");
const deseadosRoutes = require("./routes/deseados");
const pagoRoutes = require("./routes/pago");
const notificacionesRoutes = require("./routes/notificaciones");

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());

app.use("/images", express.static(path.join(__dirname, "../public/images")));

app.use("/api/juegos", juegosRoutes);
app.use("/api/carrito", carritoRoutes);
app.use("/api/auth", authRoutes);
app.use("/api/usuario", usuarioRoutes);
app.use("/api/deseados", deseadosRoutes);
app.use("/api/pago", pagoRoutes);
app.use("/api/notificaciones", notificacionesRoutes);

app.get("/api/health", (_req, res) => {
  res.json({ status: "ok" });
});

app.listen(PORT, () => {
  console.log(`GameStore API corriendo en puerto ${PORT}`);
});
