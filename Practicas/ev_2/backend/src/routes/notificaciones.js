const { Router } = require("express");
const pool = require("../db");

const router = Router();

router.get("/:userId", async (req, res) => {
  try {
    const result = await pool.query(
      "SELECT * FROM notificaciones WHERE user_id = $1 ORDER BY created_at DESC LIMIT 50",
      [req.params.userId]
    );
    res.json(result.rows);
  } catch (err) {
    console.error("Error en GET /notificaciones/:userId:", err);
    res.status(500).json({ error: "Error al obtener notificaciones" });
  }
});

router.put("/:id/leer", async (req, res) => {
  try {
    await pool.query("UPDATE notificaciones SET leida = TRUE WHERE id = $1", [req.params.id]);
    res.json({ message: "Notificación marcada como leída" });
  } catch (err) {
    console.error("Error en PUT /notificaciones/:id/leer:", err);
    res.status(500).json({ error: "Error al marcar notificación" });
  }
});

module.exports = router;
