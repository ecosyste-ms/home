//= require popper
//= require bootstrap
//= require jquery

function copyApiKey() {
  const input = document.getElementById('newApiKey');
  const button = event.currentTarget;
  const originalText = button.innerHTML;

  input.select();
  document.execCommand('copy');

  button.innerHTML = '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" class="bi bi-check me-1" viewBox="0 0 16 16"><path d="M10.97 4.97a.75.75 0 0 1 1.07 1.05l-3.99 4.99a.75.75 0 0 1-1.08.02L4.324 8.384a.75.75 0 1 1 1.06-1.06l2.094 2.093 3.473-4.425z"/></svg> Copied!';

  setTimeout(() => {
    button.innerHTML = originalText;
  }, 2000);
}
