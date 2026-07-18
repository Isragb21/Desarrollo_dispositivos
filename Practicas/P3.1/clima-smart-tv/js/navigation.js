// js/navigation.js
const NAV_MAP = {
 card0: { right:'card1', down:'card2' },
 card1: { left:'card0', down:'card3' },
 card2: { right:'card3', up:'card0' },
 card3: { left:'card2', up:'card1' },
};
let currentFocus = 'card0';
function moveFocus(nextId) {
 document.getElementById(currentFocus).classList.remove('focused');
 document.getElementById(currentFocus).setAttribute('tabindex', '-1');
 currentFocus = nextId;
 const el = document.getElementById(currentFocus);
 el.classList.add('focused');
 el.setAttribute('tabindex', '0');
 el.focus({ preventScroll: true });

 // Disparar evento de foco para actualizar el poster
 el.dispatchEvent(new CustomEvent('card-focus', {
  bubbles: true,
  detail: { cardId: nextId }
 }));
}
document.addEventListener('keydown', e => {
 const dir = {
 ArrowRight:'right', ArrowLeft:'left',
 ArrowDown:'down', ArrowUp:'up',
 }[e.key];
 if (dir) {
 e.preventDefault();
 const next = NAV_MAP[currentFocus]?.[dir];
 if (next) moveFocus(next);
 return;
 }
 // Enter / OK del control remoto — seleccionar tarjeta
 if (e.key === 'Enter' || e.key === ' ') {
 e.preventDefault();
 const card = document.getElementById(currentFocus);
 card.dispatchEvent(new CustomEvent('card-select', {
 bubbles: true,
 detail: { cardId: currentFocus }
 }));
 }
});

// Click / toque en tarjeta — seleccionar ciudad
document.querySelectorAll('.city-card').forEach(card => {
 card.addEventListener('click', () => {
 moveFocus(card.id);
 card.dispatchEvent(new CustomEvent('card-select', {
 bubbles: true,
 detail: { cardId: card.id }
 }));
 });
});
