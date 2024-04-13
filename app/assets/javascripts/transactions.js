$(function() {
  $('#successIcon').hide();
  $('#failureIcon').hide();
  $('#successIconSplit').hide();
  $('#failureIconSplit').hide();
  $('#edit-transaction-form').on('ajax:success', showTransactionUpdateIcon);
  $('#split-transactions-form').on('ajax:success', showTransactionSplitIcon);

  // Set the values for dropdowns on the transactions SHOW page
  $('#plaid-category-id').dropdown('set selected',
      $('#plaid-category-id > option').filter($("option[selected='true']")).prop('text'));
  $('#transaction-labels > option').filter($("option[data-selected='true']")).each(function(_idx, el) {
      $('#transaction-labels').dropdown('set selected', el.text)
  });

  // Add behavior to the next and previous page buttons on the transactions INDEX
  $('#previous-page-button').click(function() {
    const currentPage = getTransactionPageNum();                                                          if (currentPage > 1) {
      const newPage = currentPage - 1;
      const searchParams = getSearchParams();
      if (searchParams) {
        window.location = `/transactions?page=${newPage}&q=${searchParams}`;
      } else {
        window.location = `/transactions?page=${newPage}`;
      }
    }
  });

  $('#next-page-button').click(function() {
    const newPage = getTransactionPageNum() + 1;
    const searchParams = getSearchParams();
    if (searchParams) {
      window.location = `/transactions?page=${newPage}&q=${searchParams}`;
    } else {
      window.location = `/transactions?page=${newPage}`;
    }
  });

  // Initialize ability to edit transactions by clicking a row
  // in the table
  if (getUrl() == "transactions") {
    $('tr').click(function(obj) {
        window.location = $(this).data('url');
    })
  }

});

showTransactionUpdateIcon = function(data, status, xhr) {
  if (data.detail[0]['success']) {
    $('#successIcon').show();
  } else {
    $('#failureIcon').show();
  }
} 

showTransactionSplitIcon = function(data, status, xhr) {
  if (data.detail[0]['success']) {
    $('#successIconSplit').show();
  } else {
    $('#failureIconSplit').show();
  }
}

getUrl = function() {
  return window.location.pathname.substr(1).split("/")[0] || "home";
}
