const { Router } = require("express");
const pool = require("../db");

const router = Router();

router.get("/:userId", async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT j.* FROM carrito c
       JOIN juegos j ON j.id = c.juego_id
       WHERE c.user_id = $1
       ORDER BY c.created_at DESC`,
      [req.params.userId]
    );
    res.json(result.rows);
  } catch (err) {
    console.error("Error en GET /carrito/:userId:", err);
    res.status(500).json({ error: "Error al obtener carrito" });
  }
});

router.post("/", async (req, res) => {
  try {
    const { user_id, juego_id } = req.body;
    if (!user_id || !juego_id) {
      return res.status(400).json({ error: "user_id y juego_id son requeridos" });
    }
    await pool.query(
      "INSERT INTO carrito (user_id, juego_id) VALUES ($1, $2) ON CONFLICT DO NOTHING",
      [user_id, juego_id]
    );
    res.status(201).json({ message: "Agregado al carrito" });
  } catch (err) {
    console.error("Error en POST /carrito:", err);
    res.status(500).json({ error: "Error al agregar al carrito" });
  }
});

router.delete("/", async (req, res) => {
  try {
    const { user_id, juego_id } = req.body;
    if (!user_id || !juego_id) {
      return res.status(400).json({ error: "user_id y juego_id son requeridos" });
    }
    await pool.query(
      "DELETE FROM carrito WHERE user_id = $1 AND juego_id = $2",
      [user_id, juego_id]
    );
    res.json({ message: "Eliminado del carrito" });
  } catch (err) {
    console.error("Error en DELETE /carrito:", err);
    res.status(500).json({ error: "Error al eliminar del carrito" });
  }
});

router.delete("/clear/:userId", async (req, res) => {
  try {
    await pool.query("DELETE FROM carrito WHERE user_id = $1", [req.params.userId]);
    res.json({ message: "Carrito vaciado" });
  } catch (err) {
    console.error("Error en DELETE /carrito/clear/:userId:", err);
    res.status(500).json({ error: "Error al vaciar carrito" });
  }
});

module.exports = router;
