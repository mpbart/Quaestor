HEADER_TABS = ["home-tab", "transactions-tab", "analytics-tab", "rules-tab"]


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

getTransactionPageNum = function() {
  const page = new URL(document.URL).searchParams.get('page');
  return parseInt(page) || 1;
}

getQueryParams = function() {
  return new URL(document.URL).searchParams
}

dimPage = function() {
  $('.ui.dimmer').dimmer('show');
}

unDimPage = function() {
  $('.ui.dimmer').dimmer('hide');
}

addAccountsToWarningBanner = function(accounts) {
  elt = $('#account_refresh_failure_banner > ul')
  for (const account of accounts) {
    elt.append("<li>" + account + "</li>");
  }
}

showWarningBanner = function() {
  $('#account_refresh_failure_banner').removeClass('hidden');
}


$(function() {
 /**
  * Semantic init
  */
  getHeaderTabs().tab();  
  $('.ui.dropdown').dropdown();
  $('.ui.accordion').accordion();

 /*
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

  // Ensure that tabs are activated/deactivated on click
  getHeaderTabs().click(function(event) {

    activateTab($(event.currentTarget), $('.active'));
  });

  if (getUrl() == "home") {
    $('tr').click(function(obj) {
      Turbo.visit($(this).data('url'), {action: 'advance'});
    })
  }

  // Activate the tab for the current url
  if (HEADER_TABS.includes(`${getUrl()}-tab`)) {
    activateTab($(`#${getUrl()}-tab`), $('.active'));
  }
  $('.progress').popup();
  $('.progress .bar').popup();
});
