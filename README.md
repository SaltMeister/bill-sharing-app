## What is our app
Our App is a simple bill splitter app that intents to use AI so that the user can take a picture of their reciept and split each item with all other members.

## Use Flow
Users will first login to their account and from there, they are able to create or join a group.

Groups will have all the users who are planning on splitting a bill.

The creator of the group will be able to take a picture of the reciept and automatically display a listing of all items, and their costs.
All members of the group will be assigned to each item which will be their split that they pay to the owner of the group.

Users will use Strip to make their payments.

## Specifications
Our code is structured where, we have a 2 files that help handle our database interaction, and our User specific data.

We have a DatabaseAPI that performs our Database interactions such as creating documents, editing.
We have a UserViewModel file that stores the User specific data such as their groups and their username and email.

Our project is formatted with a launch screen view that determines if user must login/signup or go to the home screen.

From the home screen, users can view their groups or create/join groups with the + button. Clicking on groups will display the available transactions for the group. Here, the owner of the group can create transactions that automatically assign all current members of the group to each item in the transaction. Clicking on a transaction will display the data that is highlighted for the ones that the user has selected and greyed out if they are completed transactions. Group owners will have the option to lock a transaction in and as a result assigned every member their dues.

Users that have an assigned dues can find their currently active dues and make a payment to the owner of the group with stripe. 

In the home view, the user can view their account that allow them to update their user username, and view their user info and the current money they have in their account.

## Special Instructions

### App Testing Requirements
- **Camera Usage**: Our application requires access to the phone's camera to operate correctly. Ensure testing is on an actual mobile device with camera capabilities.

### Stripe Onboarding Test Data
Use the following dummy information for testing the Stripe onboarding process:

- **Test Phone Number**: Enter `000-000-0000` for any phone number fields.
- **SMS Code**: Use `000-000` when prompted for an SMS verification code.
- **Personal ID Numbers**:
  - For successful individual verification, use `000000000` for the `individual.id_number` or the `id_number` attribute on the `Person` object. For SSN's last 4 digits, `0000` will work.
- **Business Tax ID Numbers**:
  - Input `000000000` in the `company.tax_id` field for successful company verification.
- **Website Information**: Use `https://accessible.stripe.com` for website-related fields.
- **Address Validation**:
  - Input legitimate values for `city`, `state`, and `postal_code` in the `address_full_match`.

### Payment Method Simulation
For payment testing, use the following mock credit card details:
- **Card Number**: `4242424242424242`
- **CVC**: Any 3-digit number
- **Expiration Date**: Any future date

Note: These values are for testing purposes only. Switch to real data for production.

