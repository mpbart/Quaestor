$(function() {
  /**
   * Semantic init
   */
   $('#account-options').dropdown({action: 'hide'});

  /**
   * Set up event handlers
   */
  $('#refresh-button').click(function() {
    $.post('/refresh_accounts',
           function() { console.log('refreshed accounts'); });
  });
});
