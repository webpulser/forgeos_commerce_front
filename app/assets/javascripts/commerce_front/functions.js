function notifications(){
  $.getJSON('/notifications', function(data) {
    if (data.notice != null)
      $.jnotify(data.notice, 5000);
    if (data.error != null)
      $.jnotify(data.error,'error',true);
    if (data.warning != null)
      $.jnotify(data.warning,'warning', 5000);
  });
}
