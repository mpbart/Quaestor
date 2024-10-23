$(document).ready(function() {
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

  $('input[name="set-tag"]').on('change', function() {
    $('.tag-set-inputs').toggleClass('hidden', !$(this).is(':checked'));
  });

  $('.ui.dropdown').dropdown();
});
