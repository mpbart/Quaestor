const createChart = (data) => ({
  'net_worth_over_timeframe': {
    type: 'bar',
    options: {
      plugins: {
        title: {
          display: true,
          text: 'Net Worth Over Time',
          font: {
            size: 16
          }
        }
      }
    },
    data: {
      labels: data.map(row => row.month),
      datasets: [
        {
          type: 'line',
          label: 'Net Worth',
          data: data.map(row => row.assets - row.debts),
          backgroundColor: '#000000',
          borderColor: 'rgba(0, 0, 0, 0.7)',
          tension: 0.1
        },
        {
          type: 'bar',
          label: 'Assets',
          data: data.map(row => row.assets),
          backgroundColor: '#179d89'
        },
        {
          type: 'bar',
          label: 'Debts',
          data: data.map(row => row.debts),
          backgroundColor: '#9d172b'
        }
      ]
    }
  }
});


$(function() {
  getData = async function() {
    const response = await fetch('/chart_data/net_worth_over_timeframe', { method: 'GET' });
    return await response.json();
  }

  getData().then(data => {
    const chart = createChart(data)['net_worth_over_timeframe'];
    new Chart($('#analytics'), chart);
  });
});
