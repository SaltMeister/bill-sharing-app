const functions = require("firebase-functions");
const stripeSecretKey = functions.config().stripe.secret;
const stripe = require("stripe")(stripeSecretKey);
const admin = require("firebase-admin");

if (admin.apps.length === 0) {
    admin.initializeApp();
}

exports.createExpressAccount = functions.https.onCall(async (data, context) => {
    // Authentication / Authorization
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'The function must be called while authenticated.');
    }

    try {
        // Create a new Express connected account with prefilled information
        const account = await stripe.accounts.create({
            type: 'express',
            country: 'US', // Specify the country of the account
            email: data.email, // Prefill the email if available
            business_type: 'individual', // Can be 'individual' or 'company'
            requested_capabilities: ['card_payments', 'transfers'], // Specify the capabilities you want to request for this account
            // Prefill other account information if available
            individual: {
                // Add other fields as necessary
            },
            // Add business information if applicable
            // business_profile: {...},
            // Add external account (bank account or debit card) information if available
            // external_account: {...},
        });

        return { accountId: account.id }; // Return the account ID to the client
    } catch (error) {
        console.error('Error creating Express account:', error);
        throw new functions.https.HttpsError('internal', 'Unable to create Express connected account');
    }
});
// Function to create an Account Link for the Express connected account
exports.createAccountLink = functions.https.onCall(async (data, context) => {
    // Authentication / Authorization
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'The function must be called while authenticated.');
    }

    // Ensure the connected account ID is provided
    if (!data.accountId) {
        throw new functions.https.HttpsError('invalid-argument', 'The function must be called with an "accountId" argument.');
    }

    try {
        const accountLink = await stripe.accountLinks.create({
            account: data.accountId,
            refresh_url: 'yourapp://reauth', // Deep link to handle re-authentication
            return_url: 'yourapp://onboarding', // Replace with your actual return URL
            type: 'account_onboarding',
        });

        return { url: accountLink.url }; // Return the account link URL to the client
    } catch (error) {
        console.error('Error creating account link:', error);
        throw new functions.https.HttpsError('internal', 'Unable to create account link');
    }
});
