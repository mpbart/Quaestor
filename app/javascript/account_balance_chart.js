
document.addEventListener('turbo:load', function() {
  const accountId = document.getElementById('account-id-data')?.dataset.accountId;
  if (!accountId) {
    return;
  }

  fetch(`/accounts/${accountId}/balance_history`)
    .then(response => response.json())
    .then(data => {
      const labels = data.map(item => item.month);
      const balances = data.map(item => item.balance);

      const ctx = document.getElementById('balanceChart').getContext('2d');
      new Chart(ctx, {
        type: 'line',
        data: {
          labels: labels,
          datasets: [{
            label: 'Balance',
            data: balances,
            borderColor: 'rgb(75, 192, 192)',
            tension: 0.1
          }]
        },
        options: {
          responsive: true,
          maintainAspectRatio: false,
          scales: {
            y: {
              beginAtZero: false
            }
          }
        }
      });
    })
    .catch(error => console.error('Error fetching balance history:', error));
});
