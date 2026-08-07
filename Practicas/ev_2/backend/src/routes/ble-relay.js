const express = require("express");
const router = express.Router();

const relay = require("../relay-state");
const offers = require("../offers");

// Puente BLE simulado: cuando la móvil y el wearable corren en emuladores
// (sin Bluetooth), se comunican a través de estas colas HTTP.
router.get("/status", (_req, res) => {
  res.json({ wearableActive: relay.getWearableActive() });
});

// La oferta activa del momento (la publica el módulo de ofertas cada 30s).
router.get("/discount", (_req, res) => {
  res.json(offers.getActiveOffer());
});

router.post("/heartbeat", (_req, res) => {
  relay.touchHeartbeat();
  res.json({ ok: true });
});

router.post("/events", (req, res) => {
  relay.pushEvent(req.body);
  res.json({ ok: true });
});

router.get("/events", (_req, res) => {
  res.json({ events: relay.drainEvents() });
});

router.post("/responses", (req, res) => {
  relay.pushResponse(req.body);
  res.json({ ok: true });
});

router.get("/responses", (_req, res) => {
  res.json({ responses: relay.drainResponses() });
});

// El wearable deja de estar activo si no envía heartbeat.
setInterval(() => {
  if (relay.isHeartbeatStale()) {
    relay.setWearableActive(false);
  }
}, 2000);

module.exports = router;
