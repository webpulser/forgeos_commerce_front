class Order < ActiveRecord::Base

  private

  def waiting_for_cheque_event_with_notification
    waiting_for_cheque_event_without_notification
    if self.user
      Notifier.deliver_waiting_for_cheque_notification(self)
    end
  end
  alias_method_chain :waiting_for_cheque_event, :notification
end
