const { Router } = require("express");
const pool = require("../db");

const router = Router();

router.post("/", async (req, res) => {
  try {
    const { user_id } = req.body;
    if (!user_id) {
      return res.status(400).json({ error: "user_id es requerido" });
    }

    const juegos = await pool.query(
      "SELECT juego_id FROM carrito WHERE user_id = $1",
      [user_id]
    );

    if (juegos.rows.length === 0) {
      return res.status(400).json({ error: "El carrito está vacío" });
    }

    const totalJuegos = juegos.rows.length;

    await pool.query("DELETE FROM carrito WHERE user_id = $1", [user_id]);

    await pool.query(
      "UPDATE usuarios SET juegos_poseidos = juegos_poseidos + $1 WHERE id = $2",
      [totalJuegos, user_id]
    );

    await pool.query(
      "INSERT INTO notificaciones (user_id, mensaje) VALUES ($1, $2)",
      [user_id, `Compra completada: ${totalJuegos} juego(s) adquirido(s) exitosamente.`]
    );

    res.json({ message: "Pago simulado exitosamente", juegos_adquiridos: totalJuegos });
  } catch (err) {
    console.error("Error en POST /pago:", err);
    res.status(500).json({ error: "Error al procesar pago" });
  }
});

module.exports = router;
