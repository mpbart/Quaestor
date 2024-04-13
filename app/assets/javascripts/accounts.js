$(function() {
  $('#successIconAccount').hide();
  $('#failureIconAccount').hide();
  $('#successIconBalance').hide();
  $('#failureIconBalance').hide();
  $('#create-account-form').on('ajax:success', showCreateAccountIcon);
  $('#create-balance-form').on('ajax:success', showCreateBalanceIcon);
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

setAccountSubTypeMenu = function(accountType) {
if (accountType == null) {
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

showCreateAccountIcon = function(data, status, error) {                                                 if (data.detail[0]['success']) {
    $('#successIconAccount').show();
  } else {
    console.log(data.detail[0]['error']);
    $('#failureIconAccount').show();
  }
}

showCreateBalanceIcon = function(data, status, error) {
  if (data.detail[0]['success']) {
    $('#successIconBalance').show();
  } else {
    console.log(data.detail[0]['error']);
    $('#failureIconBalance').show();
  }
}
