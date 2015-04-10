
(function() {

	var ComputerDetail = React.createClass({
		render: function() {

			return (
				<div className = 'computer-detail'>
					<div className = 'row'>

					</div>
				</div>
			);
		}
	});

	function formatChildRow(row) {
		console.log(row);
		return (

		);
	}

	var table = $('#computers-table').DataTable({
		ajax: '/api/computers',

		columns: [
			{
				class: 'expand-control',
				orderable: false,
				data: null,
				defaultContent: ''
			},

			{ data: function(row) {
				return "[" + row.computer_id + "] " + row.computer_name;
			}},

			{ data: function(row) {
				return moment.unix(row.created_at).format("D MMM YYYY hh:mm");
			}},

			{ data: 'task' },
			{ data: 'message' }
		],

		order: [[1, 'asc']]

	});

	/* Add the click handler tasked with expanding and contracting the child row
	 *
	 * The child row is used to display additional information about the
	 * computer.
	 */
	$('#computers-table tbody').on('click', 'td.expand-control', function() {
		var tr = $(this).closest('tr');
		var row = table.row(tr);

		if  (row.child.isShown()) {
			row.child.hide();
			tr.removeClass('shown')

    		var chevron_container = $(this).find('.fa-chevron-circle-up');
        	chevron_container.removeClass('fa-chevron-circle-up')
        		.addClass('fa-chevron-circle-down');
		} else {
			row.child(formatChildRow(row.data)).show();
			$('.slider', row.child()).slideDown();

			tr.addClass('shown');

            var chevron_container = $(this).find('.fa-chevron-circle-down');
            chevron_container.removeClass('fa-chevron-circle-down')
            	.addClass('fa-chevron-circle-up');
		}
	});

});
