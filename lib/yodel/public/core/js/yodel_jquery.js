var Yodel = {};

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


// Remote form submission
Yodel.Forms = {
  clearStatusStates: function(form) {
    jQuery(form).find('span[data-handles]').each(function(index, statusData) {
      var status = jQuery(statusData).children().first();
      if(status) {
        status.html('');
        status.removeClass('new');
        status.removeClass('valid');
        status.removeClass('invalid');
      }
    });
  },
  
  setState: function(fieldName, form, state, message) {
    // FIXME: assumes all fields have a status element as well
    // check the form contains a field element for this message
    var field = jQuery(form).find('*[data-field=' + fieldName + ']').first();
    if(!field[0]) {
      console.log("Form does not contain a field for: " + fieldName);
      return;
    }

    var statusData = jQuery(form).find('span[data-handles*=' + fieldName + ']').first();
    var status = statusData.children().first();

    // submission of a form never transitions a field to the new state
    status.removeClass('new');    

    if(state == 'valid') {
      if(!status.hasClass('invalid')) {
        status.removeClass('invalid');
        status.addClass('valid');
      }
      field.removeClass('invalid');
      field.addClass('valid');
    } else {
      status.addClass('invalid');
      status.removeClass('valid');
      field.addClass('invalid');
      field.removeClass('valid');
    }

    // either use the supplied message, or override it with
    // a static message provided in the layout
    var staticMessage = statusData.attr('data-' + state + '-text');
    if(staticMessage)
      message = staticMessage;
    else
      message = message || '';

    // set data-errors on the field
    field.attr('data-errors', message);

    // insert or replace the status element's text. Statuses may
    // correspond to more than one field, hence concatenating msgs.
    if(message)
      if(status.html() == '')
        status.html(message);
      else
        status.html(status.html() + ', ' + message);
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
    var iframeID = 'form_' + form.attr('id') + '_iframe';
    var iframe = jQuery('#' + iframeID);
    if(iframe.length == 0) {
      form.after('<iframe id="' + iframeID + '" name="' + iframeID + '" style="display:none"></iframe>');
      form.attr('target', iframeID);
      iframe = jQuery('#' + iframeID);
      
      // FIXME: handle timeouts, failed requests
      iframe.load(function() {
        var iframeBody = iframe.contents().find('body');
        var jsonText = iframeBody.find(':contains("{")').html();
				var json = jQuery.parseJSON(jsonText);
				setTimeout(function () { iframeBody.html(''); }, 1);
				
				if(json.success) {
          Yodel.Forms.hideActivityElement(activityElement);
          var successFunction = Yodel.Forms.callbackFunction(form, 'success');
          var record = json.record;

          if(successFunction)
            successFunction(record);

        } else {
          Yodel.Forms.hideActivityElement(activityElement);
          var errorsFunction = Yodel.Forms.callbackFunction(form, 'errors');
          var errors = json.errors;

          if(errorsFunction) {
            errorsFunction(errors);
          } else {
            Yodel.Forms.clearStatusStates(form);
            form.find('*[data-field]').each(function(index, element) {
              var fieldName = jQuery(element).attr('data-field');
              if(json.errors[fieldName])
                Yodel.Forms.setState(fieldName, form, 'invalid', json.errors[fieldName]);
              else
                Yodel.Forms.setState(fieldName, form, 'valid');
            });
          }
        }
      });
    }
  }
}

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
