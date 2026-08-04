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

module.exports = router;
