const { Router } = require("express");
const pool = require("../db");

const router = Router();

router.get("/", async (req, res) => {
  try {
    const { search, genero } = req.query;
    let query = "SELECT * FROM juegos";
    const params = [];
    const conditions = [];

    if (search) {
      conditions.push("(titulo ILIKE $1 OR genero ILIKE $1 OR descripcion ILIKE $1)");
      params.push(`%${search}%`);
    }
    if (genero) {
      conditions.push("genero ILIKE $" + (params.length + 1));
      params.push(`%${genero}%`);
    }
    if (conditions.length) {
      query += " WHERE " + conditions.join(" AND ");
    }
    query += " ORDER BY rating DESC";

    const result = await pool.query(query, params);
    res.json(result.rows);
  } catch (err) {
    console.error("Error en GET /juegos:", err);
    res.status(500).json({ error: "Error al obtener juegos" });
  }
});

router.get("/:id", async (req, res) => {
  try {
    const result = await pool.query("SELECT * FROM juegos WHERE id = $1", [req.params.id]);
    if (result.rows.length === 0) {
      return res.status(404).json({ error: "Juego no encontrado" });
    }
    res.json(result.rows[0]);
  } catch (err) {
    console.error("Error en GET /juegos/:id:", err);
    res.status(500).json({ error: "Error al obtener juego" });
  }
});

module.exports = router;
