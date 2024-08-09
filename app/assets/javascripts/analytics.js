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
          label: 'Debts',
          data: data.map(row => row.debts),
          backgroundColor: '#9d172b'
        },
        {
          type: 'bar',
          label: 'Assets',
          data: data.map(row => row.assets),
          backgroundColor: '#179d89'
        }
      ]
    },
    options: {
      scales: { x: { stacked: true }, y: { stacked: true } }
    }
  },
  'spending_on_merchant_over_timeframe': {
    type: 'bar',
    options: {
      plugins: {
        title: {
          display: true,
          text: 'Merchant Spending over Time',
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
          type: 'bar',
          label: 'Spending',
          data: data.map(row => row.debts),
          backgroundColor: '#9d172b'
        },
      ]
    }
  }
});

let analyticsChart = null;


$(function() {
  $('#reportType').change(function() {
    var selectedOption = $(this).val();
    $('#merchantField').hide();
    $('#categoryField').hide();

    if (selectedOption === 'spending_on_merchant_over_timeframe') {
      $('#merchantField').show();
    } else if (selectedOption === 'spending_by_category') {
      $('#categoryField').show();
    }
  });

  $('#chartForm').submit(function(event) {
    event.preventDefault();
    renderChart();
  });

  renderChart();
});

renderChart = function() {
  const chart_type = $('#reportType').val() || 'net_worth_over_timeframe';
  getData = async function() {
    // TODO: Send the parameters from the form as part of the GET call to the
    // backend
    const response = await fetch(`/chart_data/${chart_type}`, { method: 'GET' });
    return await response.json();
  }

  getData().then(data => {
    if (analyticsChart !== null) {
      analyticsChart.destroy();
    }

    const chart = createChart(data)[chart_type];
    analyticsChart = new Chart($('#analytics'), chart);
  });
}
