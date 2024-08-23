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
          data: data.map(row => row.amount),
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
          data: data.map(row => row.amount),
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
          data: data.map(row => row.amount),
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
          data: data.map(row => row.amount),
          backgroundColor: '#179d89'
        },
      ]
    }
  }
});

let analyticsChart = null;

renderTable = function(tableData, sumValues, averageValues) {
  const table = document.getElementById('graph_data_table');
  table.innerHTML = '';

  if (tableData === null || tableData.length === 0) {
    return;
  }

  const tableHead = document.createElement('thead');
  const tableBody = document.createElement('tbody');


  const columns = Object.keys(tableData[0]).filter((k) => k != 'sort_date').sort().reverse();
  const headerRow = document.createElement('tr');
  columns.forEach(column => {
      const th = document.createElement('th');
      th.textContent = column.charAt(0).toUpperCase() + column.slice(1);
      headerRow.appendChild(th);
  });
  tableHead.appendChild(headerRow);

  tableData.forEach(item => {
    const row = document.createElement('tr');
    columns.forEach(column => {
      const td = document.createElement('td');
      td.textContent = item[column];
      row.appendChild(td);
    });
    tableBody.appendChild(row);
  });


  const summationKeys = ['assets', 'debts', 'amount'];
  if (sumValues) {
    const row = document.createElement('tr');
    const td = document.createElement('td');
    td.innerHTML = "<b>Total</b>";
    row.appendChild(td);

    columns.filter((k) => summationKeys.includes(k)).forEach(column => {
      const td = document.createElement('td');
      sum = tableData.reduce((acc, obj) => acc += obj[column], 0).toFixed(2);
      td.innerHTML = `<b>${sum}</b>`;
      row.appendChild(td);
    });

    tableBody.appendChild(row);
  } else if (averageValues) {
    const row = document.createElement('tr');
    const td = document.createElement('td');
    td.innerHTML = "<b>Average</b>";
    row.appendChild(td);

    columns.filter((k) => summationKeys.includes(k)).forEach(column => {
      const td = document.createElement('td');
      const sum = tableData.reduce((acc, obj) => acc += obj[column], 0).toFixed(2);
      const average = (sum / tableData.length).toFixed(2);
      
      td.innerHTML = `<b>${average}</b>`;
      row.appendChild(td);
    });

    tableBody.appendChild(row);
  }
  table.appendChild(tableHead);
  table.appendChild(tableBody);
}

renderChart = function(form) {
  let formData = new FormData(form);
  let params = new URLSearchParams();
  var chartType = null;

  for (const pair of formData.entries()) {
    if (pair[1] !== '' && pair[0] !== 'chart_type') {
      params.append(pair[0], pair[1])
    } else if (pair[0] == 'chart_type') {
      chartType = pair[1] || 'net_worth_over_timeframe';
    }
  }
  getData = async function() {
    const response = await fetch(`/chart_data/${chartType}?${params.toString()}`, { method: 'GET' });
    return await response.json();
  }

  getData().then(data => {
    if (analyticsChart !== null) {
      analyticsChart.destroy();
    }

    const chart = createChart(data)[chartType];
    analyticsChart = new Chart($('#analytics'), chart);

    let averageValues = false;
    let sumValues = false;
    if (chartType === 'net_worth_over_timeframe') {
      averageValues = true;
    } else {
      sumValues = true;
    }
    renderTable(data, sumValues, averageValues);
  });
}

$(function() {
  // TODO:
  // 2. Figure out how to fix the errors that occur when reloading the page
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

