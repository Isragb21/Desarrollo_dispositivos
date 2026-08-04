const { Router } = require("express");
const pool = require("../db");

const router = Router();

router.get("/:id", async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT id, username, gamertag, email, nivel, xp, xp_siguiente, juegos_poseidos,
              COALESCE(
                (SELECT json_agg(json_build_object('id', j.id, 'titulo', j.titulo, 'portada', j.portada))
                 FROM carrito c JOIN juegos j ON j.id = c.juego_id
                 WHERE c.user_id = usuarios.id), '[]'
              ) AS juegos_recientes
       FROM usuarios WHERE id = $1`,
      [req.params.id]
    );
    if (result.rows.length === 0) {
      return res.status(404).json({ error: "Usuario no encontrado" });
    }
    res.json(result.rows[0]);
  } catch (err) {
    console.error("Error en GET /usuario/:id:", err);
    res.status(500).json({ error: "Error al obtener usuario" });
  }
});

router.put("/:id", async (req, res) => {
  try {
    const { username, gamertag, email } = req.body;
    const result = await pool.query(
      `UPDATE usuarios SET
        username = COALESCE($1, username),
        gamertag = COALESCE($2, gamertag),
        email = COALESCE($3, email)
       WHERE id = $4
       RETURNING id, username, gamertag, email, nivel, xp, xp_siguiente, juegos_poseidos`,
      [username, gamertag, email, req.params.id]
    );
    if (result.rows.length === 0) {
      return res.status(404).json({ error: "Usuario no encontrado" });
    }
    res.json(result.rows[0]);
  } catch (err) {
    console.error("Error en PUT /usuario/:id:", err);
    if (err.code === "23505") {
      return res.status(409).json({ error: "El username, gamertag o email ya está en uso" });
    }
    res.status(500).json({ error: "Error al actualizar usuario" });
  }
});

module.exports = router;
