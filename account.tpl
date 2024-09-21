<!DOCTYPE html>

<html>
<head>
    <!-- Bootstrap and DataTables-->
    <script src="https://code.jquery.com/jquery-3.3.1.slim.min.js" integrity="sha384-q8i/X+965DzO0rT7abK41JStQIAqVgRVzpbzo5smXKp4YfRvH+8abtTE1Pi6jizo" crossorigin="anonymous"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/popper.js/1.14.7/umd/popper.min.js" integrity="sha384-UO2eT0CpHqdSJQ6hJty5KVphtPhzWj9WO1clHTMGa3JDZwrnQq4sF86dIHNDz0W1" crossorigin="anonymous"></script>
    <link rel="stylesheet" href="https://stackpath.bootstrapcdn.com/bootstrap/4.3.1/css/bootstrap.min.css" integrity="sha384-ggOyR0iXCbMQv3Xipma34MD+dH/1fQ784/j6cY/iJTQUOhcWr7x9JvoRxT2MZw1T" crossorigin="anonymous">
    <script src="https://stackpath.bootstrapcdn.com/bootstrap/4.3.1/js/bootstrap.min.js" integrity="sha384-JjSmVgyd0p3pXB1rRibZUAYoIIy6OrQ6VrjIEaFf/nJGzIxFDsf4x0xIM+B07jRM" crossorigin="anonymous"></script>
    <script type="text/javascript" charset="utf8" src="//cdn.datatables.net/2.1.4/js/dataTables.js"></script>
    <script type="text/javascript" charset="utf8" src="//cdn.datatables.net/2.1.4/js/dataTables.bootstrap4.js"></script>

    <script>
        $(document).ready(function() {
            // DataTable initialization
            var table = $('#data_content').DataTable({
                'columnDefs' : [{'targets':[0], 'visible' : false, 'searchable' : false }],
                // "order": [[ 3, "asc" ]]
                "ordering": false,
                "paging": false
            });
            // this is for highlighting?
            $('#data_content tbody').on('click', 'tr' , function() {
                if( $(this).hasClass('selected') ){
                    $(this).removeClass('selected');
                    $('#entry_holder').text('');
                }else{
                    table.$('tr.selected').removeClass('selected');
                    $(this).addClass('selected');
                    id = table.row( this ).data()[0];
                    //   loadentry(id);
                }
            });
            // navigating different account via select
            $('#payment_method').change( function(e) {
                window.location.href = "view?cat=" + $('#payment_method option:selected').attr('value');
            })
        });
    </script>
    <style>
        * {
        font-family: Arial, sans-serif;
        }
        .sticky_panel {
            position: sticky;
            top: 0px;
            background-color: white;
            z-index: 1;
        }
        #new_entry div.label {
        display: inline-block;
        width: 100px;
        text-align: right;
        padding-right: 5px;
        }
        #table_holder {
        width: 80%;
        margin-left: auto;
        margin-right: auto;
        }
        .payment_amount {
            display: none;
        }
        .accounting {
            display: flex;
            justify-content: space-between;
        }
        #action_panel {
            display: flex;
            justify-content: space-around;
            align-items: center;
        }
        table.summary_amounts td {
            padding: 2px 16px;
        }
    </style>
    <script>    
        var global = {};
        global.debt_payment = {{initial_debt_payment}};
        global.api_endpoint = "entry";
        global.entries = [];

        var the_data = []
        % for item in items:
            the_data.push({
                "id": "{{item['id']}}",
                "bal": {{item['balance']}},
                "payoff_type": "{{item['payoff_type'] if 'payoff_type' in item else ""}}",
                "payoff_value": {{item['payoff_value'] if 'payoff_type' in item else 0}}
            })
        % end

        fetch(global.api_endpoint+"?cat={{value_selected}}") // future needs to be template-less
        .then( response => {
            if (!response.ok) {
                throw new Error(`HTTP error, status = ${response.status}`);
            }
            return response.json();
        })
        .then( data => {
          global.entries = data.data;
          global.running = [0] //future will be start value
        })
        .catch( (error) => {
            console.log("error");
            console.log(error);
        })

        console.log(global)
        console.log(the_data)

        var update_numbers = function(id, value) {
            for(var i = 0; i < the_data.length; i++){
                if( the_data[i].id == id) {
                    the_data[i].payoff_type = value
                    break;
                }
            }
            sum_and_update();
        };
        
        var update_partial = function(obj) {
            for(var i = 0; i < the_data.length; i++){
                if( the_data[i].id == obj.dataset.id) {
                    // the_data[i].payoff_type = value
                    the_data[i].payoff_value = Number(obj.value);
                    break;
                }
            }
            sum_and_update();           
        }

        var as_accounting = function(x){
            var class_name = x < 0 ? " class='negative' " : ""
            return "<div class='accounting'><div>$ &nbsp;</div><div" + class_name + ">" +
                x.toFixed(2).replace(/\B(?=(\d{3})+(?!\d))/g, ",") + 
                "</div></div>"
        }

        var sum_and_update = function() {
            sums = [0,0,0, 0, 0]
            the_data.forEach( datum => {
                switch (datum.payoff_type) {
                    case 'interest':
                        sums[0] += datum.bal;
                        break
                    case 'full_extra':
                        sums[1] += datum.bal;
                        break
                    case 'partial_extra':
                        sums[2] += datum.payoff_value;
                        break
                    case 'full':
                        sums[3] += datum.bal;
                        break
                    case 'partial':
                        sums[4] += datum.payoff_value;
                        break
                    default:
                        break
                }
            })
            document.getElementById("total_interest").innerHTML = as_accounting(sums[0]);
            document.getElementById("total_full_extra").innerHTML = as_accounting(sums[1]);
            document.getElementById("total_partial_extra").innerHTML = as_accounting(sums[2]);
            document.getElementById("total_debt").innerHTML = as_accounting(global.debt_payment);
            document.getElementById("debt_sans_full_extra").innerHTML = as_accounting(global.debt_payment - sums[0]);
            document.getElementById("debt_sans_all_extra").innerHTML = as_accounting(global.debt_payment - sums[0] - sums[1]);
            document.getElementById("debt_check").innerHTML = as_accounting(global.debt_payment - sums[0] - sums[1] - sums[2]);

            document.getElementById("total_full").innerHTML = as_accounting(sums[3]);
            document.getElementById("total_partial").innerHTML = as_accounting(sums[4]);
            document.getElementById("total_total").innerHTML = as_accounting(sums[3] + sums[4]);
        };
    </script>
    <script>
        var highlight_row = function(obj) {
            var row = obj.parentNode.parentNode;
            var pay_amt = obj.parentNode.nextElementSibling.firstElementChild;
            switch (obj.value) {
                case 'full':
                    row.style.background = "red";
                    pay_amt.style.display= "none";
                    break;
                case 'partial':
                    row.style.background = "green";
                    pay_amt.style.display= "block";
                    break;
                case 'interest':
                    row.style.background = "cornflowerblue";
                    pay_amt.style.display= "none";
                    break;
                case 'full_extra':
                    row.style.background = "darkorange";
                    pay_amt.style.display= "none";
                    break;
                case 'partial_extra':
                    row.style.background = "cyan";
                    pay_amt.style.display= "block";
                    break;
                default:
                    row.style.background = "none";
                    pay_amt.style.display= "none";
                    break;
            }
            update_numbers(obj.dataset.id, obj.value);
        }

        var submit_change = function() {

            event.preventDefault();

            const mthd = "{{value_selected}}";
            const lbl = "{{selected}}";
            const view_id = "{{view_id}}"
            const amt = Number(document.getElementById("debt_value").value);

            global.debt_payment = amt;
            sum_and_update()

            const request = new XMLHttpRequest();
            const url = "/update_debt_payment";

            const payload = JSON.stringify({
                "debt_payment": amt,
                "value": mthd,
                "label": lbl,
                "id": view_id,
                "type": "payment_method"
            });

            request.open("POST", url, true);
            request.setRequestHeader("Content-Type", "application/json;charset=UTF-8")
            


            request.onerror = (e) => {
                console.log('error');
                // status_marker.innerHTML = 'failure';
                // status_marker.className = "badge badge-danger";
                // setTimeout( () => {
                //     status_marker.innerHTML = '';
                //     status_marker.className = "";
                // }, 3000);
            };

            request.onload = (e) => {
                if (e.currentTarget.status != 200) {
                    console.log('error');
                    // status_marker.innerHTML = 'failure: status code = ' + e.currentTarget.status;
                    // status_marker.className = "badge badge-danger";  
                } else {
                    // status_marker.innerHTML = 'success';
                    // status_marker.className = "badge badge-success";        
                    // form.reset(); // but doesn't update category though - so run function manually?
                    // other_income_forms();
                    // other_forms();
                    // window.location.reload();
                    console.log('success')
                }

                // setTimeout( () => {
                //     status_marker.innerHTML = '';
                //     status_marker.className = "";
                // }, 3000);
            };


            request.send(payload);
        }

        var submit_plan = function() {

            event.preventDefault();

            const request = new XMLHttpRequest();
            const url = "/update_payment_plan";

            const payload = JSON.stringify(the_data, null, 3);

            request.open("POST", url, true);
            request.setRequestHeader("Content-Type", "application/json;charset=UTF-8")


            request.onerror = (e) => {
                console.log('error');
            };

            request.onload = (e) => {
                if (e.currentTarget.status != 200) {
                    console.log('error');
                } else {
                    console.log('success')
                }
            };

            request.send(payload);
            }
    </script>
</head>
<body>
  <a href='/'>Home</a>
  <div>
    <select id='payment_method' name='payment_method'>
        <option>Choose Account</option>
        %for item in config['payment_methods']:
        <!-- <a class="btn btn-primary" href="view?cat={{item['value']}}">{{item['label']}}</a> -->
        <option value='{{item['value']}}'>{{item['label']}}</option>
        %end
    </select>
  </div>
  <div>
    <div class="sticky_panel">
        <h1>{{selected}}</h1>
        <div id="action_panel">
            <button class="btn btn-success" type="button" data-toggle="collapse" data-target="#add_item" aria-expanded="false" aria-controls="add_item">
                Add
            </button>
            <table id="debt_payment_summary" class="summary_amounts"><tbody>
                <tr style='background-color:cornflowerblue;'><td id='total_interest'></td><td>Interest</td><td id="amt_interest"></td><td id="total_debt"></td></tr>
                <tr style='background-color:darkorange;'><td id='total_full_extra'></td><td>Full Extra</td><td id="amt_full_extra"></td><td id="debt_sans_full_extra"></td></tr>
                <tr style='background-color:cyan;'><td id='total_partial_extra'></td><td>Partial Extra</td><td id="amt_partial_extra"></td><td id="debt_sans_all_extra"></td></tr>
                <tr><td></td><td></td><td></td><td id="debt_check"></td></tr>
            </tbody></table>
            <table id="payment_summary" class="summary_amounts"><tbody>
                <tr style='background-color:red;'><td id='total_full'></td><td>Full</td></tr>
                <tr style='background-color:green;'><td id='total_partial'></td><td>Partial</td></tr>
                <tr><td id='total_total'></td><td></td></tr>
            </tbody></table>    
            <button class="btn btn-success" type="button" onclick='submit_plan()'>
                Submit Payment Plan
            </button>
        </div>
        <div id="add_item" class="collapse">
            % include('add_entry_module.tpl', config = config)
        </div>
        <div >
            <div>Debt payment amount:</div>
            <input id="debt_value" class="debt_payment" type='number' name='debt_payment' step='0.01' value='{{initial_debt_payment}}'/>
            <button id="change_debt_payment" onclick="submit_change()">change</button>
        </div>
    </div>
    <div id='table_holder'>
        <table id='data_content' class='table table-striped table-sm table-hover'>
            <thead>
            <tr>
                <th>ID</th>
                <th>Total</th>
                <th>Balance</th>
                <th>Date</th>
                <th>Item</th>
                <th>Amount</th>
                <th>Category</th>
                <th>Notes</th>
                <th>Payment Type</th>
                <th>Payment Amount</th>
            </tr>
            </thead>
            <tbody>
            %for item in items:
            <!-- <tr data-id="{{item['id']}}" onclick="edit_entry(this)"> -->
                <!-- <tr data-entryid="{{item['id']}}" onclick="edit_entry(this)"> -->
                <tr>
                    <td data-entryid="{{item['id']}}" onclick="edit_entry(this)">{{item['id']}}</td>
                    <td data-entryid="{{item['id']}}" onclick="edit_entry(this)">${{item['show']['cum']}}</td>
                    <td data-entryid="{{item['id']}}" onclick="edit_entry(this)">${{item['show']['bal']}}</td>
                    <td data-entryid="{{item['id']}}" onclick="edit_entry(this)">{{item['date']}}</td>
                    <td data-entryid="{{item['id']}}" onclick="edit_entry(this)">{{item['item']}}</td>
                    <td data-entryid="{{item['id']}}" onclick="edit_entry(this)">${{item['show']['amt']}}</td>
                    <td data-entryid="{{item['id']}}" onclick="edit_entry(this)">{{item['category']}}</td>
                    <td data-entryid="{{item['id']}}" onclick="edit_entry(this)">{{item['notes']}}</td>
                    <td>
                        <select data-id="{{item['id']}}" class="payment_type" name='payment_type' onchange='highlight_row(this)'>
                            <option value='none'></option>
                            <option value='full'>Full</option>
                            <option value='partial'>Partial</option>
                            <option value='interest'>Interest</option>
                            <option value='full_extra'>Full Extra</option>
                            <option value='partial_extra'>Partial Extra</option>
                        </select>
                    </td>
                    <td><input data-id="{{item['id']}}" class="payment_amount" type='number' name='payment_amount' step='0.01' onchange='update_partial(this)'></td>
                </tr>
            %end
            </tbody>
        </table>
    </div>
  </div>


    <!-- Edit Entry Modal -->
    <div class="modal fade" id="edit_modal" tabindex="-1" role="dialog" aria-labelledby="edit_modal" aria-hidden="true">
        <div class="modal-dialog modal-dialog-centered" role="document">
            <div class="modal-content"><!-- <form id='edit_entry'> -->
            <div class="modal-header">
                <h5 class="modal-title" id="edit_modal_title">Edit Entry</h5>
                <button type="button" class="close" data-dismiss="modal" aria-label="Close">
                <span aria-hidden="true">&times;</span>
                </button>
            </div>
            <div class="modal-body" id="edit_modal_content">
                json goes here.
                <!-- <div class="row_form">
                <span>Type:</span>
                <select id="edit_entry_type" name="type">
                    <option value=""></option>
                    <option value="deposit">deposit</option>
                    <option value="category_bucket">category bucket</option>
                    <option value="other_bucket">other bucket</option>
                    <option value="direct">direct debit</option>
                </select>
                </div>
                <div class="row_form">
                    <span>Amount:</span>
                    <input id="edit_amount" type='number' name='amount' value="0" step="0.01" />
                </div>
                <div class="row_form">
                    <span>Date:</span>
                    <input id="edit_date" type='date' name='date' />
                </div>
                <div class="row_form">
                    <span>Item:</span>
                    <div id="edit_input_item"><input class="text_input" type='text' name='item' /></div>
                </div>
                <div class="row_form">
                    <div class="custom-control custom-switch">
                    <input type="checkbox" class="custom-control-input" id="edit_in_flight_toggle" name="in_flight">
                    <label class="custom-control-label" for="edit_in_flight_toggle">In Flight</label>
                    </div>
                </div> -->
            </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-outline-secondary" data-dismiss="modal">Close</button>
                <button type="button" class="btn btn-danger" onclick="del_entry()">Delete</button>
                <input type="submit" class="btn btn-primary" value="Submit"/>
            </div>
            <!-- </form> --></div>
        </div>
    </div>




  <script>
    sum_and_update()
    // console.log(the_data);
    for (var i = 0; i < the_data.length; i++){
        // console.log(i+"-----------------")
        if (the_data[i].payoff_type) {
            // console.log(the_data[i]);
            idx = {"full": 1, "partial": 2, "interest": 3, "full_extra": 4, "partial_extra": 5}[the_data[i].payoff_type]
            // console.log(idx)
            // console.log(`[data-id='${the_data[i].id}']`)
            var doms_to_update = document.querySelectorAll(`[data-id='${the_data[i].id}']`);
            var the_select = doms_to_update[0];
            the_select.selectedIndex = idx;
            highlight_row(the_select);
            doms_to_update[1].value = the_data[i].payoff_value;
        }
    }

  </script>
  <script>
    function edit_entry(event){
        // console.log(event.tagName)
        // console.log(event.dataset.entryid)
        global.current_id = event.dataset.entryid
        entry = global.entries.find( elem => elem.id ==  global.current_id)
        // console.log(entry)
        $('#edit_modal').modal('show');
        // $('#edit_entry_type').val(entry.type)
        // $('#edit_amount').val(entry.amount)
        // $('#edit_date').val(entry.date)
        // change_edit_input({"target": {"value": entry.type}}, entry.item)
        // $('#edit_in_flight_toggle').prop( "checked", entry.in_flight)
    }

    function del_entry(){
        console.log("DELETING")
        const url = global.api_endpoint + "/" + global.current_id;
        fetch(url, {
            method: "DELETE"
        })
        .then( response => {
            if (!response.ok) {
                throw new Error(`HTTP error, status = ${response.status}`);
            }
            window.location.reload();
            // $('#edit_modal').modal('hide');
            // $('#budget_edit')[0].reset();
            // change_edit_input({"target": {"value": "reset"}})
            return ""
        })
        .then( data => {
            console.log(data);

            // global.entries.push(payload)
            // var idx = global.entries.findIndex(elem => elem.id == global.current_id)
            // global.entries.splice( idx, 1)
            // // create_view()
            // global.current_id = "";
        })
        .catch( (error) => {
            console.log("error");
            console.log(error);
            $('#edit_modal_content').text(error);
        })
    }
  </script>
</body>

</html>
