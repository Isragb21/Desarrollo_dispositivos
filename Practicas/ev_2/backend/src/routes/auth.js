const { Router } = require("express");
const bcrypt = require("bcrypt");
const pool = require("../db");

const router = Router();

router.post("/register", async (req, res) => {
  try {
    const { username, gamertag, email, password } = req.body;
    if (!username || !gamertag || !email || !password) {
      return res.status(400).json({ error: "Todos los campos son requeridos" });
    }
    const existing = await pool.query(
      "SELECT id FROM usuarios WHERE username = $1 OR email = $2",
      [username, email]
    );
    if (existing.rows.length > 0) {
      return res.status(409).json({ error: "Usuario o email ya existe" });
    }
    const hash = await bcrypt.hash(password, 10);
    const result = await pool.query(
      `INSERT INTO usuarios (username, gamertag, email, password)
       VALUES ($1, $2, $3, $4)
       RETURNING id, username, gamertag, email, nivel, xp, xp_siguiente, juegos_poseidos`,
      [username, gamertag, email, hash]
    );
    res.status(201).json(result.rows[0]);
  } catch (err) {
    console.error("Error en POST /auth/register:", err);
    res.status(500).json({ error: "Error al registrar usuario" });
  }
});

router.post("/login", async (req, res) => {
  try {
    const { email, password } = req.body;
    if (!email || !password) {
      return res.status(400).json({ error: "Email y contraseña son requeridos" });
    }
    const result = await pool.query("SELECT * FROM usuarios WHERE email = $1", [email]);
    if (result.rows.length === 0) {
      return res.status(401).json({ error: "Credenciales inválidas" });
    }
    const user = result.rows[0];
    const match = await bcrypt.compare(password, user.password);
    if (!match) {
      return res.status(401).json({ error: "Credenciales inválidas" });
    }
    const { password: _, ...safeUser } = user;
    res.json(safeUser);
  } catch (err) {
    console.error("Error en POST /auth/login:", err);
    res.status(500).json({ error: "Error al iniciar sesión" });
  }
});

// ---- 2FA TV -> Wearable ----

/// Inicia sesión desde la TV: valida credenciales y crea una solicitud
/// pendiente que la app móvil (con wearable conectado) debe confirmar.
router.post("/login-tv", async (req, res) => {
  try {
    const { email, password } = req.body;
    if (!email || !password) {
      return res.status(400).json({ error: "Email y contraseña son requeridos" });
    }
    const result = await pool.query("SELECT * FROM usuarios WHERE email = $1", [email]);
    if (result.rows.length === 0) {
      return res.status(401).json({ error: "Credenciales inválidas" });
    }
    const user = result.rows[0];
    const match = await bcrypt.compare(password, user.password);
    if (!match) {
      return res.status(401).json({ error: "Credenciales inválidas" });
    }
    await pool.query(
      "INSERT INTO pending_logins (email, status) VALUES ($1, 'pending')",
      [email]
    );
    res.json({
      pending: true,
      message: "Pendiente de confirmación en el wearable",
    });
  } catch (err) {
    console.error("Error en POST /auth/login-tv:", err);
    res.status(500).json({ error: "Error al iniciar sesión en TV" });
  }
});

/// La TV hace polling para saber si la solicitud pendiente fue confirmada.
router.get("/check-2fa/:email", async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT status FROM pending_logins
       WHERE email = $1 ORDER BY created_at DESC LIMIT 1`,
      [req.params.email]
    );
    res.json(result.rows[0] || { status: "none" });
  } catch (err) {
    console.error("Error en GET /auth/check-2fa:", err);
    res.status(500).json({ error: "Error al verificar 2FA" });
  }
});

/// La app móvil (tras confirmación en el wearable) actualiza el estado.
router.post("/confirm-2fa", async (req, res) => {
  try {
    const { email, status } = req.body; // 'confirmed' | 'rejected'
    if (!["confirmed", "rejected"].includes(status)) {
      return res.status(400).json({ error: "Estado inválido" });
    }
    await pool.query(
      `UPDATE pending_logins SET status = $1
       WHERE email = $2 AND status = 'pending'`,
      [status, email]
    );
    res.json({ success: true });
  } catch (err) {
    console.error("Error en POST /auth/confirm-2fa:", err);
    res.status(500).json({ error: "Error al confirmar 2FA" });
  }
});

module.exports = router;
