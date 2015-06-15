
/*
 * @param type: One of ['info', 'success', 'error']
 */
function notify(title, message, type) {
	function render_tmpl(tmpl, data){
		for(var key in data) {
			console.log('Looking for: ', key)
			tmpl = tmpl.replace(new RegExp('{'+ key +'}','g'), data[key]);
		}
		return tmpl;
	}

	var message_tmpl = '<h1>{title}</h1><p>{message}</p>';

	Messenger().post({
		message: render_tmpl(message_tmpl, {title: title, message: message}),
		type: type
	});
}

function NotificationStreamer() {
	return this
}

NotificationStreamer.prototype = {
	event_processors: [
		function(checkin) {
			if (checkin['message_type'] == 'error')
				notify('Error', checkin['status'], 'error');
		},

		function(checkin) {
			if (checkin['message_type'] == 'task-end')
				notify('Task Finished', 'Finished', 'info');
		},
	],

	start: function() {
		document.addEventListener('CheckinSource:new',
			$.proxy(this.onCheckinReceived, this));
	},

	onCheckinReceived: function(event) {
		var checkin = event['detail']['data'];

		$.each(this.event_processors, function(process) {
			process(checkin);
		});
	},
}
