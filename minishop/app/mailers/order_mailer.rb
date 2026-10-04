class OrderMailer < ApplicationMailer
  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.order_mailer.confirmation.subject
  #
  def confirmation(order)
    @order = order 
    @user = order.user 

    mail(to: @user.email, subject: "Order Confirmation ##{@order.id}")
  end

  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.order_mailer.shipped.subject
  #
  def shipped(order)
    @order = order 
    @user = order.user 

    mail(to: @user.email, subject: "Your Order ##{@order.id} has been shipped")
  end
  
end
