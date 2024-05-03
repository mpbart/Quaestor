
showTransactionUpdateIcon = function(event) {
  if (event.detail.success) {
    $('#successIcon').show();
  } else {
    $('#failureIcon').show();
  }
} 

showTransactionSplitIcon = function(event) {
  if (data.detail[0]['success']) {
    $('#successIconSplit').show();
  } else {
    $('#failureIconSplit').show();
  }
}

makeTableRowsClickable = function() {
  $('tr').click(function(obj) {
      Turbo.visit($(this).data('url'), {action: 'advance'});
  })
}

getUrl = function() {
  return window.location.pathname.substr(1).split("/")[0] || "home";
}

initializePreviousPageButton = function() {
  // Add behavior to the next and previous page buttons on the transactions INDEX
  $('#previous-page-button').click(function() {
    const currentPage = getTransactionPageNum();                                                          if (currentPage > 1) {
      const newPage = currentPage - 1;
      const searchParams = getSearchParams();
      if (searchParams) {
        Turbo.visit(`/transactions?page=${newPage}&q=${searchParams}`, {action: 'replace'});
      } else {
        Turbo.visit(`/transactions?page=${newPage}`, {action: 'replace'});
      }
    }
  });
}

initializeNextPageButton = function() {
  $('#next-page-button').click(function() {
    const newPage = getTransactionPageNum() + 1;
    const searchParams = getSearchParams();
    if (searchParams) {
      Turbo.visit(`/transactions?page=${newPage}&q=${searchParams}`, {action: 'replace'});
    } else {
      Turbo.visit(`/transactions?page=${newPage}`, {action: 'replace'});
    }
  });
}

$(function() {
  $('#successIcon').hide();
  $('#failureIcon').hide();
  $('#successIconSplit').hide();
  $('#failureIconSplit').hide();
  $('#edit-transaction-form').on('turbo:submit-end', showTransactionUpdateIcon);
  $('#split-transactions-form').on('turbo:submit-end', showTransactionSplitIcon);

  // Set the values for dropdowns on the transactions SHOW page
  $('#plaid-category-id').dropdown('set selected',
      $('#plaid-category-id > option').filter($("option[selected='true']")).prop('text'));
  $('#transaction-labels > option').filter($("option[data-selected='true']")).each(function(_idx, el) {
      $('#transaction-labels').dropdown('set selected', el.text)
  });

  // Initialize ability to edit transactions by clicking a row
  // in the table
  if (getUrl() == "transactions") {
    makeTableRowsClickable();
  }
  initializePreviousPageButton();
  initializeNextPageButton();
});

// Ensure table rows are still clickable after loading a turbo frame
$('turbo-frame#transactions').on('turbo:frame-load', function(event) {
  makeTableRowsClickable();
  initializePreviousPageButton();
  initializeNextPageButton();
  $('.ui.accordion').accordion();
});
