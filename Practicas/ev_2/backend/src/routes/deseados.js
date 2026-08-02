const { Router } = require("express");
const pool = require("../db");

const router = Router();

router.get("/:userId", async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT j.* FROM deseados d
       JOIN juegos j ON j.id = d.juego_id
       WHERE d.user_id = $1
       ORDER BY d.created_at DESC`,
      [req.params.userId]
    );
    res.json(result.rows);
  } catch (err) {
    console.error("Error en GET /deseados/:userId:", err);
    res.status(500).json({ error: "Error al obtener deseados" });
  }
});

router.post("/", async (req, res) => {
  try {
    const { user_id, juego_id } = req.body;
    if (!user_id || !juego_id) {
      return res.status(400).json({ error: "user_id y juego_id son requeridos" });
    }
    await pool.query(
      "INSERT INTO deseados (user_id, juego_id) VALUES ($1, $2) ON CONFLICT DO NOTHING",
      [user_id, juego_id]
    );
    res.status(201).json({ message: "Agregado a deseados" });
  } catch (err) {
    console.error("Error en POST /deseados:", err);
    res.status(500).json({ error: "Error al agregar a deseados" });
  }
});

router.delete("/", async (req, res) => {
  try {
    const { user_id, juego_id } = req.body;
    if (!user_id || !juego_id) {
      return res.status(400).json({ error: "user_id y juego_id son requeridos" });
    }
    await pool.query(
      "DELETE FROM deseados WHERE user_id = $1 AND juego_id = $2",
      [user_id, juego_id]
    );
    res.json({ message: "Eliminado de deseados" });
  } catch (err) {
    console.error("Error en DELETE /deseados:", err);
    res.status(500).json({ error: "Error al eliminar de deseados" });
  }
});

module.exports = router;
