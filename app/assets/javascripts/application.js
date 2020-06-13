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
    // $('.active').removeClass('active');
    // $(event.currentTarget).addClass('active');
    activateTab($(event.currentTarget), $('.active'));
  });


  // Activate the tab for the current url
  activateTab($(`#${getUrl()}-tab`), $('.active'));
});


// helper methods
activateTab = function(tabToActivate, tabToDeactivate) {
  tabToDeactivate.removeClass('active');
  tabToActivate.addClass('active');
}

getUrl = function() {
  return window.location.pathname.substr(1) || "home";
}

getHeaderTabs = function() {
  return $('.tabular.menu .item').not('#link-button').not('#refresh-button');
}
