
/** Welcome, This is the biggest piece of javascript in the app so far. A little
  * bit of explanation is in order.
  *
  * The make-checkin form builds the information needed to submit a checkin
  * little by little as the user provides it.
  *
  * This explains the many callback functions.
  *
  * We must first select what user we want to checkin as. This allows the form
  * to load the set of worlds that the user has access to.
  * Once we know the world we can load the computers that exists in the world.
  *
  * You can create a totally new computer if you want or send a checkin with
  * erroneous data. You can do whatever you want !
  */

(function() {
	var computer_fields = [
		'#computer-picker', '#computer-name', '#computer-id', '#computer-type'
	];

	var checkin_fields = [
		'#message-type-picker', '#computer-task', '#computer-status',
		'#fuel-level', '#total-blocks-dug', '#total-moves'
	];

	var user_api_token = '';

	/***************************************************************************
	 *          HELPER METHODS
	 **************************************************************************/

	function disableComputerFields() {
		$.each(computer_fields, function(i, el) {$(el).prop('disabled', true)});
	}
	function enableComputerFields() {
		$.each(computer_fields, function(i, el) {$(el).prop('disabled', false)});
	}

	function disableCheckinFields() {
		$.each(checkin_fields, function(i, el) {$(el).prop('disabled', true)});
	}
	function enableCheckinFields() {
		$.each(checkin_fields, function(i, el) {$(el).prop('disabled', false)});
	}

	function handleError(error) {
		console.error('An Error ocurred: ', error)
	}

	function handleHTTPError(error) {
		var err_msg = 'HTTP Error - Code: ' + error.status  + ', Status Text: '
			+ error.statusText;

		if (error['responseText']) {
			json_error = JSON.parse(error['responseText']);
			err_msg += '. Additional Information: ' + json_error['error'];
		}

		console.error(err_msg);
	}

	/***************************************************************************
	 *          EVENT HANDLERS
	 **************************************************************************/

	/** Load the set of worlds the user has access to and save the user's api
	  * token so that we can submit the checkin when we are ready.
	  */
	function onUserSelected() {
		disableComputerFields();
		disableCheckinFields();

		var user_id = $('#user-picker option:selected').val();
		// console.log('Selected User: ', user_id, this);

		// Fetch the user's api token
		$.getJSON('/api/user/'+ user_id)
		.done(function(data){
			if (data['data'])
				user_api_token = data['data']['api_token'];
			else
				handleError(data['error'])
		})
		.fail(handleHTTPError)

		// Fetch the list of worlds the user has access to
		$.getJSON('/api/user/'+ user_id +'/world/')
		.done(function (data){
			var $world_picker = $('#world-picker');

			if (data['data']) {
				$.each(data['data'], function(i, world){
					// console.log('Adding world: ', world['name']);
					$world_picker.append(
						$('<option />', {text: world['name'], value: world['id']})
					);
				});

				$('#world-picker').prop('disabled', false);
			} else
				handleError(data['error']);

		})
		.fail(handleHTTPError);
	}

	function onWorldSelected() {
		disableComputerFields();
		disableCheckinFields();

		var user_id = $('#user-picker option:selected').val();
		var world_id =  $('#world-picker option:selected').val();

		$.getJSON('/api/user/'+ user_id +'/world/'+ world_id +'/computer')
		.done(function(data) {
			var $computer_picker = $('#computer-picker');

			if (data['data']) {
				$.each(data['data'], function(i, computer) {
					$computer_picker.append(
						$('<option />', {
							text: computer['computer_name'],
							value: computer['computer_id']
						})
					);
				});

				enableComputerFields()
			} else
			 handleError(data['error'])
		}).fail(handleHTTPError);
	}

	// TODO: Find out how change event work on radio buttons
	function onComputerCreateOrReuseSelected() {

	}

	function onComputerPicked() {
		var user_id     = $('#user-picker option:selected').val();
		var world_id    =  $('#world-picker option:selected').val();
		var computer_id = $('#computer-picker option:selected').val();

		$.getJSON('/api/user/'+ user_id +'/world/'+ world_id +'/computer/'+ computer_id)
		.done(function(data) {
			if(data['data']) {
				var computer = data['data'];

				$('#computer-id').val(computer['computer_id']);
				$('#computer-name').val(computer['computer_name']);

				$("#computer-type option").filter(function() {
					return $(this).text() == computer['computer_type'];
				}).prop('selected', true);

				enableCheckinFields();
			} else {
				handleError(data['error'])
			}
		}).fail(handleHTTPError)
	}

	function createCheckin(e) {
		e.preventDefault(); // revent the form from submitting

		var checkin = {
			api_token: user_api_token,

			world_name: $('#world-picker option:selected').text(),
			world_ticks: 0,

			computer_id:   $('#computer-id').val(),
			computer_name: $('#computer-name').val(),
			computer_type: $('#computer-type').val(),

			type: $('#message-type-picker option:selected').text(),
			task: $('#computer-task').val(),
			status: $('#computer-status').val()
		}

		console.log('Created New Checkin: ', checkin);

		$.ajax({
			method: 'POST',
			data: checkin,
			url: '/api/checkin/'
		})
		.done(function(data){
			console.log('Checkin Successful: ', data);
		})
		.fail(handleHTTPError);
	}

	$(document).ready(function() {
		var form = $('#create-checkin-form');

		// Make sure to disable all the fields We will enable them as we receive
		// more information	from the user.
		disableComputerFields();
		disableCheckinFields();

		// Load the list of worlds available to a user when the 'User' field changes
		$('#user-picker').change(onUserSelected);
		$('#world-picker').change(onWorldSelected);
		$('#computer-picker').change(onComputerPicked);

		$('#submit-btn').click(createCheckin);
	});
})();
