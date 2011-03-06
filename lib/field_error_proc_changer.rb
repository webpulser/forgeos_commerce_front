class FieldErrorProcChanger
  def initialize(proc)
    @new_proc = proc
  end

  # This will run before the action. Returning false
  # aborts the action.
  def before(controller)
    @old_proc = ActionView::Base.field_error_proc
    ActionView::Base.field_error_proc = @new_proc
    true
  end

  # This will run after the action if and only if
  # before returned true.
  def after(controller)
    ActionView::Base.field_error_proc = @old_proc
  end
end
