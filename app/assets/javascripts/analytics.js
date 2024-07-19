$(function() {
  const data = [
    { year: 2010, count: 10 },
    { year: 2011, count: 20 },
    { year: 2012, count: 15 },
    { year: 2013, count: 25 },
    { year: 2014, count: 22 },
    { year: 2015, count: 30 },
    { year: 2016, count: 28 },
  ];
  getData = async function() {
    const response = await fetch('/chart_data/net_worth_over_timeframe', { method: 'GET' });
    return await response.json();
  }

  getData().then(data => {
    console.log(data);
    new Chart(
      $('#analytics'),
      {
        type: 'bar',
        data: {
          labels: data.map(row => row.month),
          datasets: [
            {
              label: 'Assets',
              data: data.map(row => row.assets)
            },
            {
              label: 'Debts',
              data: data.map(row => row.debts)
            }
          ]
        }
      }
    );
  });
});
