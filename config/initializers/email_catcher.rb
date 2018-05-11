rails_envs = %w[development staging test]
ActionMailer::Base.register_interceptor(EmailCatcher) if rails_envs.include?(Rails.env)
