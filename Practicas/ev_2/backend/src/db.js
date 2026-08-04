const { Pool } = require("pg");

const pool = new Pool({
  host: process.env.DB_HOST || "localhost",
  port: parseInt(process.env.DB_PORT || "5432"),
  database: process.env.DB_NAME || "gamestore",
  user: process.env.DB_USER || "gamestore",
  password: process.env.DB_PASSWORD || "gamestore123",
});

module.exports = pool;
