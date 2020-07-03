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

  // Initialize modals
  $('.ui.modal').modal();
  $('tr').click(function(obj) {
    $.get('/transactions/' + obj.currentTarget.id,
          function(response) {
            $('#details-date')[0].innerText = formatDate(response.date);
            $('#details-description')[0].innerText = response.description;
            $('#details-category')[0].innerText = response.category[response.category.length -1];
            $('#details-amount')[0].innerText = response.amount;
          }
    );
    $('#transactions-modal').modal('show');
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
  return $('.tabular.menu .item').not('#link-button').not('#refresh-button').not('#account-options');
}

formatDate = function(date) {
  var d = new Date(date);
  return d.toLocaleDateString("en-US", {month: 'long', day: 'numeric'});
}
