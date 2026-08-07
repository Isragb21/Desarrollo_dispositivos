// Estado compartido del puente BLE simulado (colas de eventos/respuestas y
// presencia del wearable). Lo usan las rutas de /api/ble-relay y el módulo
// de ofertas para decidir a quién notificar (wearable o móvil).
const events = [];
const responses = [];
let wearableActive = false;
let lastHeartbeat = 0;

const HEARTBEAT_TTL_MS = 8000;

function getWearableActive() {
  return wearableActive;
}

function touchHeartbeat() {
  wearableActive = true;
  lastHeartbeat = Date.now();
}

function setWearableActive(value) {
  wearableActive = Boolean(value);
  if (!value) lastHeartbeat = 0;
}

function isHeartbeatStale() {
  return lastHeartbeat !== 0 && Date.now() - lastHeartbeat > HEARTBEAT_TTL_MS;
}

function pushEvent(event) {
  if (event && event.type) {
    events.push(event);
    while (events.length > 100) events.shift();
  }
}

function drainEvents() {
  return events.splice(0, events.length);
}

function pushResponse(response) {
  if (response && response.type) {
    responses.push(response);
    while (responses.length > 100) responses.shift();
  }
}

function drainResponses() {
  return responses.splice(0, responses.length);
}

module.exports = {
  HEARTBEAT_TTL_MS,
  getWearableActive,
  setWearableActive,
  touchHeartbeat,
  isHeartbeatStale,
  pushEvent,
  drainEvents,
  pushResponse,
  drainResponses,
};
