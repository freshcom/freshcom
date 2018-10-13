# Freshcom Identity

Freshcom Identity provides identity and access management functionalities for the Freshcom Project. It follows a combination of Stripe and AWS style IAM with the following key feature:

- Standard user CAN register.
- Standard user CAN create and own multiple accounts.
- Standard user CAN add managed user to a specific account.
- Standard user CANNOT join account created by other standard user.
- Managed user CANNOT create accounts.
- Each user have a single role used for authorization.
- Each account have a corresponding test account.
- User that have access to an account have the same access to its corresponding test account.
