const { Router } = require("express");
const pool = require("../db");

const router = Router();

// Juegos poseidos de un usuario (biblioteca), con datos completos del juego.
router.get("/:userId", async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT j.* FROM biblioteca b
       JOIN juegos j ON j.id = b.juego_id
       WHERE b.user_id = $1
       ORDER BY j.rating DESC`,
      [req.params.userId]
    );
    res.json(result.rows);
  } catch (err) {
    console.error("Error en GET /biblioteca/:userId:", err);
    res.status(500).json({ error: "Error al obtener la biblioteca" });
  }
});

module.exports = router;
