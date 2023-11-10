(async function($) {
   const fetchLinkToken = async () => {
   const response = await fetch('/create_link_token', { method: 'POST' });
   const responseJSON = await response.json();
   return responseJSON.link_token;
 };

 const configs = {
   // Required, fetch a link token from your server and pass it
   // back to your app to initialize Link.
   token: await fetchLinkToken(),
   onLoad: function() {
   // Optional, called when Link loads
   },
   onSuccess: async function(public_token, metadata) {
    // Send the public_token to your app server.
    // The metadata object contains info about the institution the
    // user selected and the account ID or IDs, if the
    // Select Account view is enabled.
    await fetch('/get_access_token', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({ public_token: public_token }),
    });
   },
   onExit: async function(err, metadata) {
     // The user exited the Link flow.
     if (err != null) {
       // The user encountered a Plaid API error prior to exiting.
       if (err.error_code === 'INVALID_LINK_TOKEN') {
         // The link_token expired or the user entered too many
         // invalid credentials. We want to destroy the old iframe
         // and reinitialize Plaid Link with a new link_token.
         handler.destroy();
         handler = Plaid.create({
           ...configs,
           token: await fetchLinkToken(),
           });
         }
     }
     // metadata contains information about the institution
     // that the user selected and the most recent API request IDs.
     // Storing this information can be helpful for support.
   },
   onEvent: function(eventName, metadata) {
     // Optionally capture Link flow events, streamed through
     // this callback as your users connect an Item to Plaid.
     // For example:
     // eventName = "TRANSITION_VIEW"
     // metadata  = {
     //   link_session_id: "123-abc",
     //   mfa_type:        "questions",
     //   timestamp:       "2017-09-14T14:42:19.350Z",
     //   view_name:       "MFA",
     // }
   }
};

let handler = Plaid.create(configs);

$('#link-button').on('click', function(e) {
  handler.open();
});
}(jQuery));
