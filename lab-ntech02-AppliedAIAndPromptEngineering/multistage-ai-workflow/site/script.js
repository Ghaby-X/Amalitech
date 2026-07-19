document.getElementById('reservation-form').addEventListener('submit', function (event) {
  event.preventDefault();

  const form = event.target;
  if (!form.checkValidity()) {
    form.reportValidity();
    return;
  }

  const name = form.elements.name.value.trim();
  const confirmation = document.getElementById('reservation-confirmation');
  confirmation.textContent = `Thanks, ${name}, we've received your request and will confirm by email shortly.`;
  confirmation.hidden = false;
  form.reset();
});
