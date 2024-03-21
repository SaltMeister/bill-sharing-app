
## Specifications
Our code is structured where, we have a 2 files that help handle our database interaction, and our User specific data.

We have a DatabaseAPI that performs our Database interactions such as creating documents, editing.
We have a UserViewModel file that stores the User specific data such as their groups and their username and email.

Our project is formatted with a launch screen view that determines if user must login/signup or go to the home screen.

From the home screen, users can view their groups or create/join groups with the + button. Clicking on groups will display the available transactions for the group. Here, the owner of the group can create transactions that automatically assign all current members of the group to each item in the transaction. Clicking on a transaction will display the data that is highlighted for the ones that the user has selected and greyed out if they are completed transactions. Group owners will have the option to lock a transaction in and as a result assigned every member their dues.

Users that have an assigned dues can find their currently active dues and make a payment to the owner of the group with stripe. 

In the home view, the user can view their account that allow them to update their user username, and view their user info and the current money they have in their account.

## Special Instructions

Our app uses the phone camera in order to function and as a result will need to be tested with an actual phone.
