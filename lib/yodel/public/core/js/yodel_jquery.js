var Yodel = {};

// Debug
Yodel.Debug = {
  show_errors: true,
  log: function() {
    if(Yodel.Debug.show_errors)
      console.log.call(arguments);
  }
}

// Security
Yodel.Security = {
  login: function(credentials, path) {
    var action = (path ? path : '/login');
    var form = jQuery('<form action="' + action + '" metod="post"/>');
    jQuery.each(credentials, function(key, value) { 
      form.append(jQuery('<input type="hidden" name="' + key + '" value="' + value + '"/>'));
    });
    form.submit();
  },
  
  remote_login: function(credentials, fns, path) {
    path = path ? path : '/login.json';
    var request = jQuery.post(path, credentials, 'json');
    request.success(function(data, textStatus, jqXHR) {
      if(fns.success)
        fns.success(data);
    });
    request.error(function(jqXHR, textStatus, errorThrown) {
      if(fns.failure) {
        var json = {};
        try {
          json = jQuery.parseJSON(jqXHR.responseText);
        } catch(err) {}
        fns.failure(json);
      }
    });
  },
  
  Facebook: {
    Window: {
      width: 1000,
      height: 480,
      title: 'Login'
    },
    redirectPath: '/facebook',
    redirectURI: null,
    clientID: '',
    scope: null
  },
  
  facebook_login: function() {
    var Options = Yodel.Security.Facebook;
    var url = 'https://www.facebook.com/dialog/oauth?client_id=' + Options.clientID;
    
    if(Options.redirectURI) {
      url += '&redirect_uri=' + Options.redirectURI;
    } else {
      url += '&redirect_uri=' + window.location.protocol + '//' + window.location.host + Options.redirectPath;
    }
    
    if(Options.scope) {
      url += '&scope=' + Options.scope;
    }
    
    var windowOptionsString = 'width=' + Options.Window.width + ',height=' + Options.Window.height;
    window.open(url, Options.Window.title, windowOptionsString);
  }
}

jQuery('*[data-oauth-login=facebook]').live('click', function(event, element) {
  Yodel.Security.facebook_login();
  event.preventDefault();
});


// Record interaction
Yodel.Records = {
  update: function(path, fields) {
    if((path.length <= 5) || (path.substr(-5,5) != '.json'))
      path = path + '.json';
    jQuery.post(path, {_method: 'put', record: JSON.stringify(fields)});
  }
};

jQuery('.yodel-remote-action').live('click', function(event, element) {
  var action = element.attr('data-action');
  if(action)
    eval(action);
});


// Forms
Yodel.Forms = {
  clearErrors: function(form) {
    jQuery(form).find('.yodel-field, .yodel-field-status').each(function(index, el) {
      var element = jQuery(el);
      
      if(element.hasClass('.yodel-field-status')) {
        element = element.children().first();
        element.html('');
      } else {
        element.data('errors', []);
      }
      
      element.removeClass('new');
      element.removeClass('valid');
      element.removeClass('invalid');
    });
  },
  
  setErrors: function(form, errors) {
    // validations are represented as:
    // {record_id: {field: [errors]},
    // embedded_record_id: {field: [errors]} ...}
    
    for(var record_id in errors) {
      var record_errors = errors[record_id];
      var selector_prefix = '.yodel-record[data-record-id=' + record_id + '] ';
      
      for(var field_name in record_errors) {
        var field_selector  = selector_prefix + ' .yodel-field[data-field=' + field_name + ']';
        var field_element   = jQuery(field_selector).first();
        
        if(field_element.length) {
          var field_errors = field_element.data('errors') || [];
          field_errors = field_errors.concat(record_errors[field_name]);
          field_element.data('errors', field_errors);
          field_element.addClass('invalid');
        }
      }
    }
  },
  
  drawStatusStates: function(form) {
    jQuery(form).find('.yodel-field').each(function(index, el) {
      // find the field's record
      var field = jQuery(el);
      var field_type = field.attr('data-field');
      var errors = field.data('errors') || [];
      var record = field.closest('.yodel-record');
      if(!record.length) {
        Yodel.Debug.log('Could not find parent record for', field);
        return;
      }
      
      // only continue if the field has an associated status element
      var status = record.find('.yodel-field-status[data-handles*=' + field_type + ']').first();
      if(!status.length)
        return;
      
      if(errors.length == 0) {
        var message = null;
        var state = 'valid';
      } else {
        // combine the errors together into a sentence - errors are
        // returned as a list and without the field type leading.
        var message = field_type.toLowerCase().replace(/_/g, ' ').replace(/\w/, function(chr) {return chr.toUpperCase()});
        message += " " + errors.join(', ');
        var state = 'invalid';
      }
      
      Yodel.Forms.setStatusState(form, field, status, state, message);
    });
  },
  
  setStatusState: function(form, field, status, state, message) {
    var status_child = status.children().first();

    // submission of a form never transitions a field to the new state
    status_child.removeClass('new');

    if(state == 'valid') {
      if(!status_child.hasClass('invalid')) {
        status_child.removeClass('invalid');
        status_child.addClass('valid');
      }
      field.removeClass('invalid');
      field.addClass('valid');
    } else {
      status_child.addClass('invalid');
      status_child.removeClass('valid');
      field.addClass('invalid');
      field.removeClass('valid');
    }

    // either use the supplied message, or override it with
    // a static message provided in the layout
    var staticMessage = status.attr('data-' + state + '-text');
    if(staticMessage)
      message = staticMessage;
    else
      message = message || '';

    // set data-errors on the field
    field.attr('data-errors', message);

    // insert or replace the status element's text. Statuses may
    // correspond to more than one field, hence concatenating msgs.
    if(message) {
      var current_status_text = status_child.html();
      if(current_status_text == '')
        status_child.html(message);
      else
        status_child.html(current_status_text + ', ' + message);
    }
  },
  
  handleFailure: function(activityElement, form, data) {
    var failureFunction = Yodel.Forms.callbackFunction(form, 'failure');
    Yodel.Forms.hideActivityElement(activityElement);
    if(failureFunction)
      failureFunction(data);
  },
  
  callbackFunction: function(form, name) {
    var functionName = form.attr('data-' + name + '-function');
    if(functionName) {
      var functionReference = eval(functionName);
      if(functionReference)
        return functionReference;
    }
    return null;
  },
  
  hideActivityElement: function(activityElement) {
    if(activityElement)
      activityElement.css('visibility', 'hidden');
  },
  
  submit: function(event, element) {
    var form = jQuery(element);
    
    // show the activity indicator if present
    var activityElement = form.find('.yodel-form-activity')
    activityElement.css('visibility', 'visible');
    
    // create an iframe to handle the submission if necessary. iframes
    // are used instead of ajax calls so file uploads can be supported
    // the iframe is created once, and the form set to submit to it.
    var iframeID = 'form_' + form.attr('id') + '_iframe';
    var iframe = jQuery('#' + iframeID);
    if(iframe.length == 0) {
      form.after('<iframe id="' + iframeID + '" name="' + iframeID + '" style="display:none"></iframe>');
      form.attr('target', iframeID);
      iframe = jQuery('#' + iframeID);
      
      // FIXME: handle timeouts, failed requests
      iframe.load(function() {
        var iframeBody = iframe.contents().find('body');
        var jsonText = $("<div />").html(iframeBody.find(':contains("{")').html()).text();
				var json = jQuery.parseJSON(jsonText);
				json = json ? json : {}; // ensure json is an object (invalid json will make jQuery.parseJSON return null)
				setTimeout(function () { iframeBody.html(''); }, 1);
				
				if(json.success) {
          Yodel.Forms.hideActivityElement(activityElement);
          var successFunction = Yodel.Forms.callbackFunction(form, 'success');
          var record = json.record;
          
          if(successFunction)
            successFunction(record, json);
          else
            window.location = record.path;
            
        } else {
          Yodel.Forms.hideActivityElement(activityElement);
          var errorsFunction = Yodel.Forms.callbackFunction(form, 'errors');
          var errors = json.errors;
          
          if(errorsFunction) {
            errorsFunction(errors);
          } else {
            Yodel.Forms.clearErrors(form);
            Yodel.Forms.setErrors(form, errors);
            Yodel.Forms.drawStatusStates(form);
          }
        }
      });
    }
  }
}

// remote form submission
if(jQuery.browser.msie) {
  jQuery('form').live('focusin', function(focusEvent) {
    var form = focusEvent.target;
    if(jQuery(form).attr('data-remote') == 'true' && !form.builtSubmitEvent) {
      jQuery(form).submit(function(submitEvent) {
        Yodel.Forms.submit(submitEvent, submitEvent.target);
      });
      form.builtSubmitEvent = true;
    }
  });
} else {
  jQuery('form[data-remote=true]').live('submit', function(event) {
    Yodel.Forms.submit(event, event.target);
  });
}

// checkbox values
$('.field-type-boolean input[type=checkbox]').live('change', function(event) {
  $(this).siblings('input[type=hidden]').val(this.checked + '');
});
