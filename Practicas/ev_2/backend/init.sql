CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE IF NOT EXISTS juegos (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  titulo VARCHAR(200) NOT NULL,
  genero VARCHAR(100) NOT NULL,
  descripcion TEXT,
  precio DECIMAL(10,2) NOT NULL DEFAULT 0,
  rating DECIMAL(3,2) DEFAULT 0,
  portada VARCHAR(500) DEFAULT '',
  etiquetas TEXT[] DEFAULT '{}',
  descuento DECIMAL(10,2) DEFAULT NULL,
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS usuarios (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  username VARCHAR(100) UNIQUE NOT NULL,
  gamertag VARCHAR(100) UNIQUE NOT NULL,
  email VARCHAR(200) UNIQUE NOT NULL,
  password VARCHAR(255) NOT NULL,
  nivel INT DEFAULT 1,
  xp INT DEFAULT 0,
  xp_siguiente INT DEFAULT 1000,
  juegos_poseidos INT DEFAULT 0,
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS carrito (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
  juego_id UUID NOT NULL REFERENCES juegos(id) ON DELETE CASCADE,
  created_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(user_id, juego_id)
);

INSERT INTO juegos (titulo, genero, descripcion, precio, rating, portada, etiquetas, descuento) VALUES
('Cyberpunk 2077', 'RPG', 'Aventura de mundo abierto en Night City.', 1099, 4.6, '/images/cyberpunk_2077.jpg', ARRAY['Acción', 'Mundo Abierto', 'Cyberpunk'], NULL),
('Elden Ring', 'RPG', 'El nuevo RPG de acción de FromSoftware.', 1299, 4.8, '/images/elden_ring.jpg', ARRAY['RPG', 'Acción', 'Fantasía', 'Mundo Abierto'], NULL),
('God of War Ragnarök', 'Acción', 'Kratos y Atreus enfrentan el Ragnarök.', 999, 4.9, '/images/god_of_war_ragnarok.jpg', ARRAY['Acción', 'Aventura', 'Mitología'], 799),
('Stray', 'Aventura', 'Un gato perdido en una ciudad cyberpunk.', 549, 4.5, '/images/stray.jpg', ARRAY['Aventura', 'Gatos', 'Cyberpunk'], NULL),
('Hollow Knight', 'Metroidvania', 'Un viaje épico a través de Hallownest.', 249, 4.7, '/images/hollow_knight.jpg', ARRAY['Metroidvania', 'Acción', 'Indie'], NULL),
('Red Dead Redemption 2', 'Acción', 'El Salvaje Oeste cobra vida.', 1099, 4.9, '/images/red_dead_redemption_2.jpg', ARRAY['Acción', 'Mundo Abierto', 'Western'], NULL),
('The Legend of Zelda: TOTK', 'Aventura', 'Explora los cielos y la superficie de Hyrule.', 1299, 4.8, '/images/zelda_totk.jpg', ARRAY['Aventura', 'Mundo Abierto', 'Fantasía'], NULL),
('Celeste', 'Plataformas', 'Ayuda a Madeline a escalar la montaña Celeste.', 349, 4.6, '/images/celeste.jpg', ARRAY['Plataformas', 'Indie', 'Difícil'], NULL),
('DOOM Eternal', 'FPS', 'Destruye demonios al ritmo de la acción.', 799, 4.7, '/images/doom_eternal.jpg', ARRAY['FPS', 'Acción', 'Violento'], 599),
('Stardew Valley', 'Simulación', 'Construye tu granja y vive en el campo.', 249, 4.8, '/images/stardew_valley.jpg', ARRAY['Simulación', 'Relajante', 'Indie', 'Agricultura'], NULL);

CREATE TABLE IF NOT EXISTS deseados (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
  juego_id UUID NOT NULL REFERENCES juegos(id) ON DELETE CASCADE,
  created_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(user_id, juego_id)
);

CREATE TABLE IF NOT EXISTS pending_logins (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  email VARCHAR(200) NOT NULL,
  status VARCHAR(20) DEFAULT 'pending', -- pending, confirmed, rejected
  created_at TIMESTAMP DEFAULT NOW()
);

INSERT INTO usuarios (username, gamertag, email, password, nivel, xp, xp_siguiente, juegos_poseidos) VALUES
('shadowblade', 'ShadowBlade99', 'shadow@mail.com', '$2b$10$8K1p/a0dL1LXMIgoEDFrwOfMQkLzMk2h1tqMnTkpIXGhL6vXvTDOy', 42, 3200, 5000, 15),
('neongamer', 'NeonGamer_X', 'neon@mail.com', '$2b$10$8K1p/a0dL1LXMIgoEDFrwOfMQkLzMk2h1tqMnTkpIXGhL6vXvTDOy', 27, 1800, 3000, 8),
('Isra', 'Isra', 'gomezbonilla06@gmail.com', '$2b$10$z8FGmfXSmnC2I0YyqB.CceskB7ZJPT6oqZYlGht9cotxXGr8lqILa', 1, 0, 1000, 0);
