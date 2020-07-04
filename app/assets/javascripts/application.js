HEADER_TABS = ["home-tab", "transactions-tab", "analytics-tab", "budgets-tab"]

$(function() {
 /**
  * Semantic init
  */
  $('#account-options').dropdown({action: 'hide'});
  getHeaderTabs().tab();  

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
  $('tr').click(function(obj) {
    window.location = $(this).data('url');
  });

  // Activate the tab for the current url
  if (HEADER_TABS.includes(`${getUrl()}-tab`)) {
    activateTab($(`#${getUrl()}-tab`), $('.active'));
  }
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
  return window.location.pathname.substr(1) || "home";
}

getHeaderTabs = function() {
  return $('.tabular.menu .item').not('#link-button').not('#refresh-button').not('#account-options');
}

formatDate = function(date) {
  var d = new Date(date);
  return d.toLocaleDateString("en-US", {month: 'long', day: 'numeric'});
}
