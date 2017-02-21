$(document).ready ->
  $(document).bind 'ajaxError', 'form#new_key', (event, jqxhr, settings, exception) ->
    # note: jqxhr.responseJSON undefined, parsing responseText instead
    $(event.data).render_form_errors $.parseJSON(jqxhr.responseText)
    return
  return

(($) ->
  
  $('#server_wizard_os_type').on 'change', (e) ->
    if ($(this).val().includes("windows") || $(this).val().includes("freebsd"))
      $('input[name="server_wizard[ssh_key_ids][]"]').attr 'checked', false
      $('input[name="server_wizard[ssh_key_ids][]"]').attr 'disabled', true
      $('a[id="new-ssh-key"]').attr 'disabled', true
    else
      $('input[name="server_wizard[ssh_key_ids][]"]').attr 'disabled', false
      $('a[id="new-ssh-key"]').attr 'disabled', false

  $.fn.modal_success = ->
    # close modal
    @modal 'hide'
    # clear form input elements
    @find('form input[type="text"]').val ''
    @find('form textarea[id="key_key"]').val ''
    # clear error state
    @clear_previous_errors()
    $('[data-toggle="tooltip"]').tooltip()
    return

  $.fn.render_form_errors = (errors) ->
    $form = this
    @clear_previous_errors()
    model = @data('model')
    # show error messages in input form-group help-block
    $.each errors, (field, messages) ->
      $input = $('input[name="' + model + '[' + field + ']"]')
      $input.closest('.form-group').addClass('has-error').find('.help-block').html messages.join(' & ')
      $text = $('textarea[name="' + model + '[' + field + ']"]')
      $text.closest('.form-group').addClass('has-error').find('.help-block').html messages.join(' & ')
      return
    return

  $.fn.clear_previous_errors = ->
    $('.form-group.has-error', this).each ->
      $('.help-block', $(this)).html ''
      $(this).removeClass 'has-error'
      return
    return

  return
) jQuery
