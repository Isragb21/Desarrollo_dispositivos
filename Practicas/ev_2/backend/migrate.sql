-- migracion: wishlist, notificaciones + usuario Isra (seguro para BD existente)

CREATE TABLE IF NOT EXISTS deseados (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
  juego_id UUID NOT NULL REFERENCES juegos(id) ON DELETE CASCADE,
  created_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(user_id, juego_id)
);

CREATE TABLE IF NOT EXISTS notificaciones (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
  mensaje TEXT NOT NULL,
  leida BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT NOW()
);

INSERT INTO usuarios (username, gamertag, email, password, nivel, xp, xp_siguiente, juegos_poseidos)
SELECT 'Isra', 'Isra', 'gomezbonilla06@gmail.com', '$2b$10$z8FGmfXSmnC2I0YyqB.CceskB7ZJPT6oqZYlGht9cotxXGr8lqILa', 1, 0, 1000, 0
WHERE NOT EXISTS (SELECT 1 FROM usuarios WHERE username = 'Isra' OR email = 'gomezbonilla06@gmail.com');
