
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
		var $computer_name = $('#computer-name');
		var $computer_id   = $('#computer-id');
		var $computer_type  = $('#comuter-type');

		var user_id     = $('#user-picker option:selected').val();
		var world_id    =  $('#world-picker option:selected').val();
		var computer_id = $('#computer-picker option:selected').val();

		$.getJSON('/api/user/'+ user_id +'/world/'+ world_id +'/computer/'+ computer_id)
		.done(function(data) {
			if(data['data']) {
				$computer_name.val(data['data']['computer_name']);
				$computer_id.val(data['data']['computer_id']);

				// TODO: FInd out how to select an option with jquery
				$computer_type.val(data['data']['computer_type']);

				enableCheckinFields();
			} else {
				handleError(data['error'])
			}
		}).fail(function(error) {
			handleError(error)
		})
	}

	// TOOD: Find out how to override the default submit bahaviour
	// TODO: Create a chcekin
	function onSubmit() {}

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
	});
})();
