# Paypal implementation

Intervac uses Paypal as one of the payment gateways.  We're currently using
[Accelerated Boarding for Express Checkout](https://www.paypalobjects.com/webstatic/en_US/developer/docs/pdf/limited-release/PP_AcceleratedBoarding_Guide.pdf).

The main idea is to provide an easy way to set-up a new account to receive money
using Paypal. A new agent, for example, could start working with us with their
email address only and create a Paypal account when the first payment is
received.

Paypal configuration is being defined by environment and is located under
`config/environments/(.*).rb`. Our production environment is pointing to
`intervac-paypal_api1.modondo.com` and we relly need to understand why, as we
are not working directly with Modondo anymore.

We keep logs of all transactions on our database through `PaypalIpnLog`.
