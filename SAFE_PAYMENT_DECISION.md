# Subscription Payment Security Decision

Two requested behaviors were intentionally not implemented because they would create a direct payment-security vulnerability:

1. **The portal does not collect or store CVC values.** Card CVC must never be retained by this application. Card number, expiry and CVC entry should be hosted/tokenized by a PCI-compliant payment provider.
2. **Self-entered card/bank details do not automatically activate a paid plan.** Without a payment-provider confirmation, any user could enter invented values and obtain a paid subscription.

## Current safe behavior

- The Carrier records non-sensitive transfer details.
- Operations can verify the transfer through the existing control.
- Finance and Operations have a read-only catalog showing available plans and every Carrier's selected plan.

## Correct future automatic flow

1. Redirect the Carrier to a provider-hosted checkout.
2. The provider collects card number, expiry and CVC; McCollins never receives or stores the CVC.
3. The provider sends a signed server-to-server webhook after successful payment.
4. McCollins validates the signature and payment amount/reference.
5. Only then does the backend automatically activate or schedule the subscription.

This preserves the approved database and prevents unverified paid-plan activation.
