
  <style>
  /*
  * {
	  font-family: Arial, sans-serif;
	}
  */
  /*
  #new_entry {
    width: 1300px;
  }
	#new_entry div.label {
  */
  div.label {
	  display: inline-block;
	  width: 130px;
	  text-align: right;
	  padding-right:5px;
	}
  /*
	#table_holder {
	  width: 80%;
	  margin-left:auto;
	  margin-right:auto;
	}
	#form_holder {
	  display: inline-block;
	  width:400px;
	  vertical-align: top;
	}
	#entry_holder {
	  display: inline-block;
	  width:800px;
	  vertical-align: top;
	}
  */
  /*
  .container {
    display: inline-block;
    width: 400px;
    padding: 10px;
    vertical-align: bottom;
  }
  */
  /*
  .submit_container {
    margin-left: 190px;
  }
  */
  </style>

  <script>
  function other_forms() {
    var y = document.getElementById('category').value;
    var x = document.getElementById('for_extra_inputs');
    x.innerHTML = '';
      %for item in config['categories']:
        %if "subcategories" in item or "other_inputs" in item:
          if(y == '{{item['value']}}'){
          %if "subcategories" in item:
            %for subcat in item['subcategories']:
              x.innerHTML += "<div class='label'>{{subcat["label"]}}:</div>" +
                "<select id='{{subcat["select_id"]}}' name='{{subcat["select_name"]}}'>" +
              %for opts in subcat['options']:
                "<option value='{{opts['value']}}'>{{opts['label']}}</option>" +
              %end
                "</select><br />";
            %end
          %end
          %if "other_inputs" in item:
            %for an_input in item['other_inputs']:
                x.innerHTML +=  "<div class='label'>{{an_input['label']}}:</div>" +
                  "<input type='{{an_input['input_type']}}' name='{{an_input['input_name']}}' " +
                %if "step" in an_input:
                  "step='{{an_input['step']}}'" +
                %end
                  "/>";
            %end
          %end
          }
        %end

      %end

  }
  </script>

  <script>
  function other_income_forms() {
    var y = document.getElementById('income_category').value;
    var x = document.getElementById('name_options');
    
    if(y == 'interest'){
      x.innerHTML = "<div class='label'>Name:</div><select name='name'> \
        <option value='American Express Savings'>American Express Savings</option> \
        <option value='Austin Telco Savings'>Austin Telco Savings</option> \
        <option value='Bank of America Checking'>Bank of America Checking</option> \
        <option value='Bank of America Savings'>Bank of America Savings</option> \
        <option value='Capital One 360 Savings'>Capital One 360 Savings</option> \
        </select>";
    } else if(y == 'dividend'){
        x.innerHTML = "<div class='label'>Name:</div><select name='name'> \
          <option value='American Campus Communities'>American Campus Communities</option> \
          </select>";
    } else if(y == 'salary') {
        //x.innerHTML = "<div class='label'>Name:</div><select name='name'> \
        //  <option value='Cosmic Lens Consulting'>Cosmic Lens Consulting</option> \
        //  </select>";
        let salary_input = "<div class='label'>Name:</div>"
        salary_input += "<select name='name'>"
        %for item in config['income_sources']['salary']:
          salary_input += "<option value='{{item['value']}}'>{{item['label']}}</option>"
        %end
        salary_input += "</select>"
        x.innerHTML = salary_input;
    } else if (y == 'business'){
      x.innerHTML = "<div class='label'>Name:</div><select name='name'> \
        <option value='Cosmic Lens Consulting'>Cosmic Lens Consulting</option> \
        </select>";
    } else {
      x.innerHTML = "<div class='label'>Name:</div><select name='name'> \
        <option value='other'>Other</option> \
        </select>";
    }

    x = document.getElementById('for_income_extras');
    if(y == 'interest'){
      x.innerHTML = "<div class='label'>Balance:</div><input type='number' step='0.01' name='balance'/><br />"
    } else if(y == 'dividend'){
      x.innerHTML = '';
    } else if(y == 'salary'){
        x.innerHTML = `<div class='label'>Gross Pay:</div><input type='number' step='0.01' name='gross_pay'/><br /> 
            <div class='blockLabel'>Deductions:</div><br/> 
            <div id='salaryVoluntaryDeductions'> 
              <div class='blockLabel'>Voluntary:</div><br /> 
              <div class='label'>Health:</div><input type='number' step='0.01' name='health'/><br /> 
              <div class='label'>Dental:</div><input type='number' step='0.01' name='dental'/><br /> 
              <div class='label'>Vision:</div><input type='number' step='0.01' name='vision'/><br /> 
              <div class='label'>FSA:</div><input type='number' step='0.01' name='fsa'/><br /> 
            </div> 
            <div class='blockLabel'>Statutory:</div><br /> 
            <div class='label'>Income Tax:</div><input type='number' step='0.01' name='income_tax'/><br /> 
            <div class='label'>Social Security:</div><input type='number' step='0.01' name='ss_tax'/><br /> 
            <div class='label'>Medicare:</div><input type='number' step='0.01' name='medicare_tax'/><br /> 
            <div class='label'>Retirement:</div><br /> 
            <div class='label'>401k:</div><input type='number' step='0.01' name='retirement'/><br />
            <div class='label'>match:</div><input type='number' step='0.01' name='retire_match'/><br />
            <div class='label'>Other:</div><br /> 
            <div class='label'>ADD:</div><input type='number' step='0.01' name='add'/><br /> 
            <div class='label'>Life:</div><input type='number' step='0.01' name='life'/><br /> 
            <div class='label'>ADD+Life:</div><input type='number' step='0.01' name='addlife'/><br />  
            <div class='label'>Spouse LIfe:</div><input type='number' step='0.01' name='spouselife'/><br /> 
            <div class='label'>Accident:</div><input type='number' step='0.01' name='accident'/><br /> 
            <div class='label'>Critical Illness:</div><input type='number' step='0.01' name='critillness'/><br /> 
            <div class='label'>LTD:</div><input type='number' step='0.01' name='ltd'/><br /> 
            <div class='label'>ID Protection:</div><input type='number' step='0.01' name='id'/><br /> `
    } else  if (y == 'business'){
      x.innerHTML = '';
    } else {
      x.innerHTML = "<div class='label'>Notes:</div><textarea name='notes' rows='5' cols='40'></textarea>";
    }

  }
  </script>

  <script>
  function post_form(x) {

    event.preventDefault();

    let form = '';
    let status_marker = '';
    if (x === 'income') {
      form = document.getElementById("new_entry_income");
      status_marker = document.getElementById("submission_status_income");
    } else if (x === 'expense') {
      form = document.getElementById("new_entry_expenses");
      status_marker = document.getElementById("submission_status_expense");
    } else {
      //WARNING
      form = document.getElementById("new_entry_income");
      status_marker = document.getElementById("submission_status_income");
    }
    const form_data = new FormData(form);

    const request = new XMLHttpRequest();
    const url = "/add_entry";

    request.open("POST", url, true);


    request.onerror = (e) => {
      status_marker.innerHTML = 'failure';
      status_marker.className = "badge badge-danger";
      setTimeout( () => {
        status_marker.innerHTML = '';
        status_marker.className = "";
      }, 3000);
    };

    request.onload = (e) => {
      if (e.currentTarget.status != 200) {
        status_marker.innerHTML = 'failure: status code = ' + e.currentTarget.status;
        status_marker.className = "badge badge-danger";  
      } else {
        // status_marker.innerHTML = 'success';
        // status_marker.className = "badge badge-success";        
        form.reset(); // but doesn't update category though - so run function manually?
        other_income_forms();
        other_forms();
        window.location.reload();
      }

      setTimeout( () => {
        status_marker.innerHTML = '';
        status_marker.className = "";
      }, 3000);
    };


    request.send(form_data);
  };
  </script>





<!-- <body onload='other_forms(); other_income_forms();'> -->


    <ul class="nav nav-pills mb-3" id="pills-tab" role="tablist">
      <li class="nav-item">
        <a class="nav-link active" id="pills-expenses-tab" data-toggle="pill" href="#pills-expenses" role="tab" aria-controls="pills-expenses" aria-selected="true">Expenses</a>
      </li>
      <li class="nav-item">
        <a class="nav-link" id="pills-income-tab" data-toggle="pill" href="#pills-income" role="tab" aria-controls="pills-income" aria-selected="false">Income</a>
      </li>
    </ul>


    <div class="tab-content" id="pills-tabContent" style="width:100%;">
      <section class="tab-pane fade show active" id="pills-expenses" role="tabpanel" aria-labelledby="pills-expenses-tab">
        <form id='new_entry_expenses' style="width:100%;">
          <div class="row justify-content-center"><div class='col' style='text-align:center;'>
            <h1>Enter New Entry</h1>
          </div></div>
          <div class="row justify-content-center" style='margin-top:15px;'>
            <div class="col" id='main input' style='text-align:right;'>
              <div class='label'>Date:</div><input type='date' name='date'><br />
              <div class='label'>Category: </div>
                <select id='category' name='category'>
                  %for item in config['categories']:
                    <option value='{{item['value']}}'>{{item['label']}}</option>
                  %end
                </select>
                <br />
              <div class='label'>Payment Method: </div>
                <select id='payment_method' name='payment_method'>
                  %for item in config['payment_methods']:
                    <option value='{{item['value']}}'>{{item['label']}}</option>
                  %end
                </select>
                <br />
              <div class='label'>Item: </div><input type='text' name='item' /><br />
              <div class='label'>Amount:</div><input type='number' name='amount' step='0.01'><br />
            </div>
            <div class='col' id='extra input'>
              <div id='for_extra_inputs'></div>
            </div>
          </div>
          <div class="row justify-content-center" style='margin-top:15px;'><div class="col" style="text-align:center;">
            <div class='label'>Notes:</div><textarea name="notes" rows="5" cols="40"></textarea>
            <br />
            <input type='submit' value='Submit' style="width:200px;height:50px;">
            <div><span id="submission_status_expense" style="transition: all 2s;"></span></div>
          </div></div>
        </form>
      </section>

      <section class="tab-pane fade" id="pills-income" role="tabpanel" aria-labelledby="pills-income-tab">
        <!-- <form id='new_entry_income' action='/add_entry/income' method='post' style="width:100%;"> -->
        <form id='new_entry_income' style='width:100%;'>
          <div class="row justify-content-center"><div class='col' style='text-align:center;'>
            <h1>Enter New Entry</h1>
          </div></div>
          <div class="row justify-content-center" style='margin-top:15px;'>
            <div class="col" id='income_input' style='text-align:right;'>
              <div class='label'>Date:</div><input type='date' name='date'><br />
              <div class='label'>Category: </div>
                <select id='income_category' name='category'>
                  <option value='business'>Business Income</option>
                  <option value='dividend'>Dividend</option>
                  <option value='interest'>Interest</option>
                  <option value='other'>Other (e.g. gifts)</option>
                  <option value='salary'>Salary</option>
                </select>
                <br />
              <div id='name_options'></div>
              <div class='label'>Amount:</div><input type='number' name='amount' step='0.01'><br />
              <div id='for_income_extras'></div>
              <br />
              <input type='submit' value='Submit' style="width:200px;height:50px;">
              <div><span id="submission_status_income" style="transition: all 2s;"></span></div>
            </div>
            <div class="col" id='income_buffer'></div>
          </div>
        </form>
      </section>
    </div>




<script>
  document.getElementById('category').addEventListener('change',other_forms);
  document.getElementById('income_category').addEventListener('change',other_income_forms);
  document.getElementById('new_entry_income').addEventListener('submit',() => post_form('income'));
  document.getElementById('new_entry_expenses').addEventListener('submit',() => post_form('expense'));
</script>

