initializeCheckboxes = function() {
  $('input[name="matches-amount"]').on('change', function() {
    $('.amount-inputs').toggleClass('hidden', !$(this).is(':checked'));
  });

  $('input[name="matches-account"]').on('change', function() {
    $('.account-inputs').toggleClass('hidden', !$(this).is(':checked'));
  });

  $('input[name="matches-description"]').on('change', function() {
    $('.description-inputs').toggleClass('hidden', !$(this).is(':checked'));
  });

  $('input[name="rename-merchant"]').on('change', function() {
    $('.merchant-rename-inputs').toggleClass('hidden', !$(this).is(':checked'));
  });

  $('input[name="set-description"]').on('change', function() {
    $('.description-set-inputs').toggleClass('hidden', !$(this).is(':checked'));
  });

  $('input[name="set-category"]').on('change', function() {
    $('.category-set-inputs').toggleClass('hidden', !$(this).is(':checked'));
  });

  $('input[name="set-label"]').on('change', function() {
    $('.label-set-inputs').toggleClass('hidden', !$(this).is(':checked'));
  });
}

$(function() {
  $('.ui.dropdown').dropdown();
  initializeCheckboxes();
});

$('turbo-frame#rules').on('turbo:frame-load', function(event) {
  $('.ui.dropdown').dropdown();
  initializeCheckboxes();
});
