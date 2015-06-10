
(function() {
	var computer_fields = [
		'#computer-picker', '#computer-name', '#computer-id', '#computer-type'
	];

	var checkin_fields = [
		'#message-type-picker', '#task', '#status',, '#fuel-level',
		'#total-blocks-dug', '#total-moves'
	];

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

	/***************************************************************************
	 *          EVENT HANDLERS
	 **************************************************************************/


	function onUserSelected() {
		disableComputerFields();
		disableCheckinFields();

		var user_id = $('#user-picker option:selected').val();
		// console.log('Selected User: ', user_id, this);

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
		.fail(function(data) {
			handleError(data['error']);
		});
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
		}).fail(function(error) {
			handleError(error)
		});
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
		}).fail(function(error) {
			handleError(error)
		})
	}

	function createCheckin(e) {
		e.preventDefault(); // revent the form from submitting

		var checkin = {
			api_token: 'invalid-token-todo',

			world_name: $('#world-picker option:selected').text(),
			world_ticks: 0,

			computer_id:   $('#computer-id').val(),
			computer_name: $('#computer_name').val(),
			computer_type: $('#computer_type').val(),

			type: $('message_type option:selected').text(),
			task: $('computer_task').val(),
			status: $('comuter_status').val()
		}

		console.log('Created New Checkin: ', checkin);

		$.ajax({
			method: 'POST',
			data: checkin,
			url: '/api/checkin/'
		}).done(function(data){
			console.log('Checkin Successful: ', data);
		}).fail(function(err) {
			handleError(err);
		});
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
