HEADER_TABS = ["home-tab", "transactions-tab", "analytics-tab", "budgets-tab"]

$(function() {
 /**
  * Semantic init
  */
  $('#account-options').dropdown({action: 'hide'});
  getHeaderTabs().tab();  
  $('.ui.dropdown').dropdown();
  $('.ui.accordion').accordion();
  $('#plaid-category-id').dropdown('set selected',
      $('#plaid-category-id > option').filter($("option[selected='true']")).prop('text'));
  $('#transaction-labels > option').filter($("option[data-selected='true']")).each(function(_idx, el) {
      $('#transaction-labels').dropdown('set selected', el.text)
  });
  setAccountSubTypeMenu($('#account_type').val());

 /**
  * Set up event handlers
  */
  $('#add-account-button').click(function() {
    const button = $('#add-account-button');
    if (button.css('border-width')[0] == '1') {
      button.css('border-width', '0px');
    } else {
      button.css('border-width', '1px');
    }
  });

 /**
  * Refresh Accounts Button with behavior to show warning banner
  * if an error is returned
  */
  $('#refresh-button').click(function() {
    dimPage();
    $.post('/refresh_accounts',
      function(data) {
        unDimPage();
        if (data.failed_accounts.length != 0) {
          addAccountsToWarningBanner(data.failed_accounts);
          showWarningBanner();
        }
      });
  });

 /**
  * Add behavior to dismiss warning banner if the x is clicked
  */
  $('#account_refresh_failure_banner').on('click', function() {
    $(this).closest('.message').transition('fade');
  });

  $('#account_type').change(function() {
    const accountType = $(this).val();

    setAccountSubTypeMenu(accountType);
  });

  // Ensure that tabs are activated/deactivated on click
  getHeaderTabs().click(function(event) {

    activateTab($(event.currentTarget), $('.active'));
  });

  // Set behavior of next and previous page buttons for transactions
  $('#previous-page-button').click(function() {
    const currentPage = getTransactionPageNum();
    if (currentPage > 1) {
      const newPage = currentPage - 1;
      window.location = `/transactions?page=${newPage}`;
    }
  });

  $('#next-page-button').click(function() {
    const newPage = getTransactionPageNum() + 1;
    window.location = `/transactions?page=${newPage}`;
  });

  // Initialize ability to edit transactions by clicking a row
  // in the table
  if (getUrl() == "transactions") {
    $('tr').click(function(obj) {
        window.location = $(this).data('url');
    })
  }

  if (getUrl() == "home") {
    $('tr').click(function(obj) {
      window.location = $(this).data('url');
    })
  }

  // Activate the tab for the current url
  if (HEADER_TABS.includes(`${getUrl()}-tab`)) {
    activateTab($(`#${getUrl()}-tab`), $('.active'));
  }

  $('#successIcon').hide();
  $('#failureIcon').hide();
  $('#successIconSplit').hide();
  $('#failureIconSplit').hide();
  $('#edit-transaction-form').on('ajax:success', showTransactionUpdateSuccessIcon);
  $('#edit-transaction-form').on('ajax:failure', showTransactionUpdateFailureIcon);
  $('#split-transactions-form').on('ajax:success', showTransactionSplitUpdateSuccessIcon);
  $('#split-transactions-form').on('ajax:failure', showTransactionSplitUpdateFailureIcon);
  $('#edit-transaction-button').click(function(data, _h) {
    console.log(data.currentTarget.form);
  });
});


// helper methods
activateTab = function(tabToActivate, tabToDeactivate) {
  if (!HEADER_TABS.includes(tabToActivate[0].id)) {
    return;
  }
  tabToDeactivate.removeClass('active');
  tabToActivate.addClass('active');
}

getUrl = function() {
  return window.location.pathname.substr(1).split("/")[0] || "home";
}

getHeaderTabs = function() {
  return $('.tabular.menu .item').not('#link-button').not('#refresh-button').not('#account-options');
}

formatDate = function(date) {
  var d = new Date(date);
  return d.toLocaleDateString("en-US", {month: 'long', day: 'numeric'});
}

showTransactionUpdateSuccessIcon = function(data, status, xhr) {
  if (data.detail[0]['success']) {
    $('#successIcon').show();
  } else {
    $('#failureIcon').show();
  }
}

showTransactionUpdateFailureIcon = function(xhr, status, error) {
  $('#failureIcon').show();
}

showTransactionSplitUpdateSuccessIcon = function(data, status, xhr) {
  if (data.detail[0]['success']) {
    $('#successIconSplit').show();
  } else {
    $('#failureIconSplit').show();
  }
}

showTransactionSplitUpdateFailureIcon = function(xhr, status, error) {
  $('#failureIconSplit').show();
}

getTransactionPageNum = function() {
  const page = new URL(document.URL).searchParams.get('page');
  return parseInt(page) || 1;
}

setAccountSubTypeMenu = function(accountType) {
  if (accountType == null) {
    return;
  }

  $.get(`/accounts/subtypes/${accountType}`, function(data) {
    const values = data.subtypes.map(x => Object({name: x.replace('_', ' '), value: x}));
    $('#account_sub_type').dropdown('setup menu', {
      values: values
    });
    $('#account_sub_type').addClass('ui dropdown');

    $('#account_sub_type').dropdown('refresh');
  });
}

dimPage = function() {
  $('.ui.dimmer').dimmer('show');
}

unDimPage = function() {
  $('.ui.dimmer').dimmer('hide');
}

addAccountsToWarningBanner = function(accounts) {
  elt = $('#account_refresh_failure_banner > ul')
  console.log(accounts);
  for (const account of accounts) {
    elt.append("<li>" + account + "</li>");
  }
}

showWarningBanner = function() {
  $('#account_refresh_failure_banner').removeClass('hidden');
}
