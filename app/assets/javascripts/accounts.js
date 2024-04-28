
setAccountSubTypeMenu = function(accountType) {
if (accountType == null || accountType == "") {
  return;
}

  $.get(`/accounts/subtypes/${accountType}`, function(data) {
    var subTypeSelect = $('#account_sub_type');
    const values = data.subtypes.map(x => Object({name: x.replace('_', ' '), value: x}));

    subTypeSelect.empty();
    $.each(values, function(idx, option) {
      subTypeSelect.append($('<option>', {value: option.value, text: option.name}));
    });
  });
}

showCreateAccountIcon = function(event) {
  if (event.detail.success) {
    $('#successIconAccount').show();
  } else {
    console.log(event.detail);
    $('#failureIconAccount').show();
  }
}

showCreateBalanceIcon = function(event) {
  if (event.detail.success) {
    $('#successIconBalance').show();
  } else {
    console.log(event.detail);
    $('#failureIconBalance').show();
  }
}
$(function() {
  $('#successIconAccount').hide();
  $('#failureIconAccount').hide();
  $('#successIconBalance').hide();
  $('#failureIconBalance').hide();
  $('#create-account-form').on('turbo:submit-end', showCreateAccountIcon);
  $('#create-balance-form').on('turbo:submit-end', showCreateBalanceIcon);
  $('#account-options').dropdown({action: 'hide'});

  setAccountSubTypeMenu($('#account_type').val());

  // Add event handlers
  $('#add-account-button').click(function() {
    const button = $('#add-account-button');
    if (button.css('border-width')[0] == '1') {
      button.css('border-width', '0px');
    } else {
      button.css('border-width', '1px');
    }
  });


  $('#account_type').change(function() {
    const accountType = $(this).val();

    setAccountSubTypeMenu(accountType);
  });
});
