
var CheckinSource = {
	checkins    : {},
	is_connected: false,
	listen_url: 'ws://localhost:8100/checkin/stream',

	listen: function() {
		var self = this;

		if (self.is_connected) {
			console.info('Already listening for changes')
			return
		}

		console.info('Starting CheckinSource Listner ...');
		console.info('Listening on:', self.listen_url);

		var CheckinSocket = new WebSocket(self.listen_url);

		CheckinSocket.onmessage = function(message) {
			console.debug('CheckinSource:listen - New Message');

			var event = new CustomEvent('CheckinSource:new', { 'detail':  message});
			document.dispatchEvent(event);
		};
	},
};
