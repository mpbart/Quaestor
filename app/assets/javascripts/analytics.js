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
          data: data.map(row => row.total),
          backgroundColor: '#0982aa'
        },
      ]
    }
  },
  'spending_on_detailed_category_over_timeframe': {
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
          data: data.map(row => row.total),
          backgroundColor: '#0982aa'
        },
      ]
    }
  },
  'spending_over_timeframe': {
    type: 'bar',
    options: {
      plugins: {
        title: {
          display: true,
          text: 'Total Spending over Time',
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
          data: data.map(row => row.total),
          backgroundColor: '#0982aa'
        },
      ]
    }
  },
  'income_over_timeframe': {
    type: 'bar',
    options: {
      plugins: {
        title: {
          display: true,
          text: 'Total Income over Time',
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
          label: 'Income',
          data: data.map(row => row.total),
          backgroundColor: '#179d89'
        },
      ]
    }
  }
});

let analyticsChart = null;

renderChart = function(form) {
  let formData = new FormData(form);
  let params = new URLSearchParams();
  var chart_type = null;

  for (const pair of formData.entries()) {
    if (pair[1] !== '' && pair[0] !== 'chart_type') {
      params.append(pair[0], pair[1])
    } else if (pair[0] == 'chart_type') {
      chart_type = pair[1] || 'net_worth_over_timeframe';
    }
  }
  getData = async function() {
    const response = await fetch(`/chart_data/${chart_type}?${params.toString()}`, { method: 'GET' });
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

$(function() {
  // TODO:
  // 1. Think about adding a chart under the graph showing numbers with an average
  // 2. Figure out how to fix the errors that occur when reloading the page
  // 3. Investigate supporting time ranges instead of hardcoding to 12 months
  // IDEAS:
  // 1. Add chart for showing spending by tag
  // 2. Add chart for showing spending on top 3 categories per month
  // 3. Add a sankey diagram for showing flows of money?
  $('#chartType').change(function() {
    var selectedOption = $(this).val();
    $('#merchantField').hide();
    $('#categoryField').hide();

    if (selectedOption === 'spending_on_merchant_over_timeframe') {
      $('#merchantField').show();
      $('#categoryDropdown').dropdown('clear');
    } else if (selectedOption === 'spending_on_detailed_category_over_timeframe') {
      $('#categoryField').show();
      $('#merchantInput').val('');
    } else {
      $('#categoryDropdown').dropdown('clear');
      $('#merchantInput').val('');
    }
  });

  $('#chartForm').submit(function(event) {
    event.preventDefault();
    renderChart(this);
  });

  renderChart($('#chartForm')[0]);
});

