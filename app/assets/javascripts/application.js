HEADER_TABS = ["home-tab", "transactions-tab", "analytics-tab", "budgets-tab"]

$(function() {
 /**
  * Semantic init
  */
  $('#account-options').dropdown({action: 'hide'});
  getHeaderTabs().tab();  
  $('.ui.dropdown').dropdown();
  $('#plaid-category-id').dropdown('set selected',
      $('#plaid-category-id > option').filter($("option[selected='true']")).prop('text'));
  $('#transaction-labels > option').filter($("option[data-selected='true']")).each(function(_idx, el) {
      $('#transaction-labels').dropdown('set selected', el.text)
  });


 /**
  * Set up event handlers
  */
  $('#refresh-button').click(function() {
    $.post('/refresh_accounts',
           function() { console.log('refreshed accounts'); });
  });

  // Ensure that tabs are activated/deactivated on click
  getHeaderTabs().click(function(event) {

    activateTab($(event.currentTarget), $('.active'));
  });

  // Initialize ability to edit transactions by clicking a row
  // in the table
  if(getUrl() == "transactions") {
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
