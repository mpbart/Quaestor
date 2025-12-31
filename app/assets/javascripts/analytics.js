var analyticsChart = null;
var chartColors = [
  '#1f77b4', '#ff7f0e', '#2ca02c', '#d62728', '#9467bd',
  '#8c564b', '#e377c2', '#7f7f7f', '#bcbd22', '#17becf',
  '#aec7e8', '#ffbb78', '#98df8a', '#ff9896', '#c5b0d5',
  '#c49c94', '#f7b6d2', '#c7c7c7', '#dbdb8d', '#9edae5'
];

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

renderChart = function(form, chartCreator) {
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

    const chart = chartCreator(data)[chartType];
    analyticsChart = new Chart($('#analytics'), chart);

    let averageValues = false;
    let sumValues = false;
    if (chartType === 'net_worth_over_timeframe') {
      averageValues = true;
    } else {
      sumValues = true;
    }
    if (chartType != 'spending_by_category_over_timeframe') {
      renderTable(data, sumValues, averageValues);
    }
  });
}

currentDate = function() {
  const date = new Date(Date.now());
  let day = date.getDate();
  let month = date.getMonth();
  const year = date.getFullYear();
  if (day < 10) {
    day = `0${day}`
  }
  if (month < 9) {
    month = `0${month + 1}`
  } else {
    month = `${month + 1}`
  }
  return `${year}-${month}-${day}`;
}

oneYearAgoMonthlyDate = function() {
  const date = new Date(Date.now());
  let month = date.getMonth();
  const year = date.getFullYear();
  if (month < 9) {
    month = `0${month + 1}`
  } else {
    month = `${month + 1}`
  }
  return `${year - 1}-${month}-01`;
}

beginningOfCurrentYearDate = function() {
  const date = new Date(Date.now());
  const year = date.getFullYear();
  return `${year}-01-01`;
}

initTimeframeField = function(selectedOption) {
  $('#startDateField').hide();
  $('#endDateField').hide();

  if (selectedOption === 'custom') {
    $('#startDateField').show();
    $('#endDateField').show();
  } else if(selectedOption === 'last_12_months') {
    $('#startDateInput').val(oneYearAgoMonthlyDate());
    $('#endDateInput').val(currentDate());
  } else if(selectedOption === 'year_to_date') {
    $('#startDateInput').val(beginningOfCurrentYearDate());
    $('#endDateInput').val(currentDate());
  } else if(selectedOption === 'all_time') {
    $('#startDateInput').val('2000-01-01');
    $('#endDateInput').val(currentDate());
  }
}

$(function() {
  // IDEAS:
  // 1. Add a sankey diagram for showing flows of money?

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
    'spending_on_label_over_timeframe': {
      type: 'bar',
      options: {
        plugins: {
          title: {
            display: true,
            text: 'Spending over Time on label',
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
    'spending_by_category_over_timeframe': {
      type: 'bar',
      options: {
        plugins: {
          title: {
            display: true,
            text: 'Spending by Category over Time',
            font: {
              size: 16
            }
          }
        },
        scales: {
          x: {
            stacked: true,
          },
          y: {
            stacked: true
          }
        }
      },
      data: (function() {
        if (!data || data.length === 0) {
          return { labels: [], datasets: [] };
        }
        const labels = [...new Set(data.map(item => item.month))].sort((a, b) => new Date(Date.parse(a)) - new Date(Date.parse(b)));
        const categories = [...new Set(data.map(item => item.category))];

        const datasets = categories.map((category, index) => {
          return {
            label: category,
            data: labels.map(label => {
              const found = data.find(item => item.month === label && item.category === category);
              return found ? found.total : 0;
            }),
            backgroundColor: chartColors[index % chartColors.length]
          };
        });

        return { labels, datasets };
      })()
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

  $('#chartType').change(function() {
    var selectedOption = $(this).val();
    $('#merchantField').hide();
    $('#categoryField').hide();
    $('#labelField').hide();

    if (selectedOption === 'spending_on_merchant_over_timeframe') {
      $('#merchantField').show();
      $('#categoryDropdown').dropdown('clear');
      $('#merchantInput').val('');
      $('#labelDropdown').val('');
    } else if (selectedOption === 'spending_on_detailed_category_over_timeframe') {
      $('#categoryField').show();
      $('#merchantInput').val('');
      $('#labelDropdown').val('');
    } else if (selectedOption === 'spending_on_label_over_timeframe') {
      $('#labelField').show();
      $('#merchantInput').val('');
      $('#categoryDropdown').dropdown('clear');
    } else {
      $('#labelDropdown').val('');
      $('#categoryDropdown').dropdown('clear');
      $('#merchantInput').val('');
    }
  });

  $('#timeframeField').change(function() {
    initTimeframeField($(this).val());
  });

  if ($('#timeframeField').val() === 'custom') {
    $('#startDateField').show();
    $('#endDateField').show();
  }

  $('#chartForm').submit(function(event) {
    event.preventDefault();
    renderChart(this, createChart);
  });

  initTimeframeField($('#timeframeField').val());
  renderChart($('#chartForm')[0], createChart);
});
