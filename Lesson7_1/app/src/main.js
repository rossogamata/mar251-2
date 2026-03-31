// Відображаємо інформацію про середовище виконання у footer
const runtimeInfo = document.getElementById('runtime-info');

if (runtimeInfo) {
  const now = new Date();
  const formatted = now.toLocaleString('uk-UA', {
    dateStyle: 'long',
    timeStyle: 'short',
  });
  runtimeInfo.textContent = `Запущено: ${formatted} | Node env: ${import.meta.env.MODE}`;
}

// Плавна прокрутка для навігаційних посилань
document.querySelectorAll('a[href^="#"]').forEach(link => {
  link.addEventListener('click', e => {
    e.preventDefault();
    const target = document.querySelector(link.getAttribute('href'));
    if (target) {
      target.scrollIntoView({ behavior: 'smooth' });
    }
  });
});
