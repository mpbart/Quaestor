
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

showCreateLabelIcon = function(event) {
  if (event.detail.success) {
    $('#successIconLabel').show();
  } else {
    console.log(event.detail);
    $('#failureIconLabel').show();
  }
}

showCreateCategoryIcon = function(event) {
  if (event.detail.success) {
    $('#successIconCategory').show();
  } else {
    console.log(event.detail);
    $('#failureIconCategory').show();
  }
}

makeListItemClickable = function() {
  $('.clickable-list-item').click(function(obj) {
      Turbo.visit($(this).data('url'), {action: 'advance'});
  })
}

initHomepageElements = function() {
  $('#successIconAccount').hide();
  $('#failureIconAccount').hide();
  $('#successIconBalance').hide();
  $('#failureIconBalance').hide();
  $('#successIconLabel').hide();
  $('#failureIconLabel').hide();
  $('#successIconCategory').hide();
  $('#failureIconCategory').hide();
  $('#create-account-form').on('turbo:submit-end', showCreateAccountIcon);
  $('#create-balance-form').on('turbo:submit-end', showCreateBalanceIcon);
  $('#create-label-form').on('turbo:submit-end', showCreateLabelIcon);
  $('#create-category-form').on('turbo:submit-end', showCreateCategoryIcon);
  $('#account-options').dropdown({action: 'hide'});

  setAccountSubTypeMenu($('#account_type').val());

  makeListItemClickable();
  $('.progress').progress({showActivity: false});
}

$(function() {
  $('#primary-category-dropdown').dropdown({ allowAdditions: true, hideAdditions: false });
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

  initHomepageElements();

  $('turbo-frame#home').on('turbo:frame-load', function(event) {
    initHomepageElements();
    $('#primary-category-dropdown').dropdown({ allowAdditions: true, hideAdditions: false });
    $('.ui.dropdown:not(#primary-category-dropdown)').dropdown();
    $('.ui.accordion').accordion();
  });
});
