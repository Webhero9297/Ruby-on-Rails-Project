module Accounts::PaymentsHelper
  ##
  # Checks if it is time to show the renewal hints and buttons
  def time_for_renewal(account)
    subscription = account.current_subscription

    subscription.expires_at < 60.days.from_now.utc and subscription.expires_at > Time.now.utc and subscription.kind == 'paid'
  end

  def early_renewal(account)
    subscription = account.current_subscription

    subscription.expires_at >= 60.days.from_now.utc and subscription.expires_at <= 180.days.from_now.utc and subscription.kind == 'paid'
  end

  def time_for_upgrade(account)
    subscription = account.current_subscription

    subscription.expires_at < 90.days.from_now.utc and subscription.expires_at > Time.now.utc and subscription.kind == 'free'
  end

  def upgrade_button
    link_to(t('button.upgrade_membership'), upgrade_subscriptions_url, class: 'btn btn-primary')
  end

  def renewal_button
    link_to(t('button.renew_membership'), renew_subscriptions_url, class: 'btn btn-primary')
  end
end
