const pool = require("./db");
const relay = require("./relay-state");

// Oferta del momento: cada 30s se elige un juego del catálogo, se le aplica
// un descuento real (UPDATE a `descuento`) y se notifica. Si el wearable está
// activo, el evento `discount` se publica en la cola del puente (la app del
// reloj lo muestra); si no, la móvil lo detecta vía GET /api/ble-relay/discount
// y muestra la notificación en el celular.
const OFFER_INTERVAL_MS = 30000;

let activeOffer = null;

function randInt(min, max) {
  return Math.floor(Math.random() * (max - min + 1)) + min;
}

async function pickGame() {
  const { rows } = await pool.query(
    "SELECT id, titulo, precio FROM juegos WHERE descuento IS NULL ORDER BY random() LIMIT 1"
  );
  return rows[0];
}

async function applyOffer() {
  try {
    let game = await pickGame();
    if (!game) {
      // Todos los juegos están en oferta: reinicia los descuentos para que
      // la rotación de ofertas nunca se detenga.
      await pool.query("UPDATE juegos SET descuento = NULL");
      game = await pickGame();
    }
    if (!game) return;

    const percent = randInt(15, 40);
    const newPrice = Math.round(game.precio * (1 - percent / 100) * 100) / 100;

    // "Ponerlo realmente en oferta": se actualiza el precio rebajado en BD.
    await pool.query("UPDATE juegos SET descuento = $1 WHERE id = $2", [
      newPrice,
      game.id,
    ]);

    activeOffer = {
      game: game.titulo,
      percent,
      oldPrice: Number(game.precio),
      newPrice,
      updatedAt: Date.now(),
    };

    console.log(
      `[Ofertas] ${game.titulo} en oferta -${percent}% ($${Number(game.precio).toFixed(2)} -> $${newPrice})`
    );

    if (relay.getWearableActive()) {
      relay.pushEvent({ type: "discount", game: game.titulo, percent });
    }
  } catch (err) {
    console.error("[Ofertas] Error aplicando oferta:", err);
  }
}

function startOffers() {
  // Publica una oferta nada más arrancar y después cada 30 segundos.
  applyOffer();
  setInterval(applyOffer, OFFER_INTERVAL_MS);
}

module.exports = {
  startOffers,
  getActiveOffer: () => activeOffer,
};
