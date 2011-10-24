load File.join(Gem.loaded_specs['forgeos_commerce'].full_gem_path, 'app', 'models', 'order.rb')
Order.class_eval do

  private

  def waiting_for_cheque_event_with_notification
    waiting_for_cheque_event_without_notification
    if self.user
      Notifier.deliver_waiting_for_cheque_notification(self)
    end
  end
  alias_method_chain :waiting_for_cheque_event, :notification
end
