
import os
import json
import datetime
import time
from uuid import uuid4
import traceback


import bottle
from dotenv import load_dotenv


#CONFIGS ---------------------------------------------------------------------

PORT = 8888
load_dotenv()
DATA_DIR = os.getenv('DATA_DIR')
CONFIG_DIR = os.getenv('CONFIG_DIR')
BUDGET_DIR = os.getenv('BUDGET_DIR')

#PREPROCESSING ---------------------------------------------------------------

with open("configuration.json") as json_file:
	legacy_config = json.load(json_file)
	
def process_dt(x):
	x['date'] = datetime.datetime.strptime(x['date'],"%Y-%m-%d %H:%M:%S")
	return x

def get_files(dir):
	file_names = os.listdir(dir)
	import_files = [json.load(open(dir+x)) for x in file_names]
	return file_names, import_files
	
entry_files = os.listdir(DATA_DIR)
entries = [json.load(open(DATA_DIR+x)) for x in entry_files if x[0] != "."]

configuration_files = os.listdir(CONFIG_DIR)
configurations = [(json.load(open(CONFIG_DIR+x)),x) for x in configuration_files]

budget_files, budget_entries = get_files(BUDGET_DIR)
# for legacy data
for entry in budget_entries:
	if 'in_flight' not in entry:
		entry['in_flight']= False

#process form into right data types
def process_form_data(entry_form):
	to_enter = {}
	for key,value in entry_form.items():
		new_value = value
		try:
			new_value = float(new_value)
		except:
			pass
		try:
			new_value = datetime.datetime.strptime(value, "%Y-%m-%d")
		except:
			pass
		to_enter[key] = new_value
	return to_enter

def dt2str(dt: datetime):
	return dt.strftime("%Y-%m-%d %H:%M:%S") 

#-----------------------------------------------------------------------------

@bottle.route('/')
def index():
	return bottle.template('add_entry', config = legacy_config)

@bottle.route('/budget_view')
def budget_html():
    return bottle.static_file('budget.html', root='./')

# VIEW BUDGET
@bottle.route('/budget')
def get_budget():
	bottle.response.headers['Content-Type'] = 'application/json'
	bottle.response.headers['Cache-Control'] = 'no-cache'
	return json.dumps({
		"config": legacy_config,
		"data": budget_entries
    })

# ADD BUDGET ENTRY
@bottle.post('/budget_entry')
def add_budget_entry():
	data = bottle.request.json
	print(data)
	# future - check for duplicate entries
	new_id = str(uuid4())
	data['id'] = new_id
	with open(BUDGET_DIR+new_id+".json", 'w', encoding = "utf-8") as f:
		json.dump(data, f, ensure_ascii=False, indent = 4)#, default = dt2str)
	budget_entries.append(data)
	bottle.response.headers['Content-Type'] = 'application/json'
	return json.dumps({'id': new_id})

# EDIT BUDGET ENTRY
@bottle.put('/budget_entry/<id>')
def update_budget_entry(id):
    ids = [x["id"] for x in budget_entries]
    try:
        print(id not in ids)
        if id not in ids:
            raise KeyError
        data = bottle.request.json
        if data['id'] != id:
            print('id doesnt match path')
            raise ValueError
        idx = ids.index(id)
		# should be more thorough, keep the entry and add back in case issues with pop or rmeoving file
        budget_entries[idx] = data
        with open(BUDGET_DIR+id+".json", 'w', encoding = 'utf-8') as f:
            json.dump(data, f, ensure_ascii = False, indent = 4)
    except KeyError:
        bottle.response.status = 404
        return
    except ValueError:
        bottle.response.status = 400
        return
    bottle.response.headers['Content-Type'] = 'application/json'
    return	json.dumps({"id": id})

# DELETE BUDGET ENTRY
@bottle.delete('/budget_entry/<id>')
def delete_budget_entry(id):
	ids = [x["id"] for x in budget_entries]
	try:
		if id not in ids:
			raise KeyError
		idx = ids.index(id)
		# should be more thorough, keep the entry and add back in case issues with pop or rmeoving file
		budget_entries.pop(idx) 
		os.remove(BUDGET_DIR+id+".json")
	except KeyError:
		bottle.response.status = 404
		return
	return

# GET EXPENSE ENTRIES
@bottle.get('/entry')
def get_entries():
    payment_method = bottle.request.query.cat if bottle.request.query.cat else legacy_config['payment_methods'][0]["value"]

    # for backwards compatibility -- future all configuration in separate json and with uuid
    # label = next(o for o in legacy_config["payment_methods"] if o['value'] == payment_method)['label']
    selected_view = [x for x in entries if 'payment_method' in x and x['payment_method'] == payment_method]
    selected_view.sort(key = lambda x: x["date"], reverse = False)

    running = 0
    for obj in selected_view:
        running = running + obj['balance']
        obj['cumulative'] = running
        obj['show'] = {
            "cum": "{:.2f}".format(obj['cumulative']),
			"bal": "{:.2f}".format(obj['balance']),
			"amt": "{:.2f}".format(obj['amount']),
        }

    # print(json.dumps(selected_view,indent = 3))
	
    bottle.response.headers['Content-Type'] = 'application/json'
    bottle.response.headers['Cache-Control'] = 'no-cache'
    return json.dumps({
		"data": selected_view
    })

# ADD EXPENSE ENTRY --- should be modified to be generic for income/expense
@bottle.post('/add_entry')
def add_new_entry_expense():
	entry_form = bottle.request.forms
	to_enter = process_form_data(entry_form)
	# print(to_enter)
	to_enter["id"] = str(uuid4())
	to_enter["date"] = dt2str(to_enter["date"])
	to_enter["balance"] = to_enter["amount"]
	# try:
	with open(DATA_DIR+to_enter["id"]+".json", 'w', encoding = "utf-8") as f:
		json.dump(to_enter, f, ensure_ascii=False, indent = 4)#, default = dt2str)
	entries.append(to_enter)
    # except:
        # print("error adding entry")
        # add things to make sure file is not written if error with pushing to data and vice versa
	return 'success'

# DELETE EXPENSE ENTRY
@bottle.delete('/entry/<id>')
def delete_entry(id):
	ids = [x["id"] for x in entries]
	try:
		if id not in ids:
			raise KeyError
		idx = ids.index(id)
		# should be more thorough, keep the entry and add back in case issues with pop or rmeoving file
		entries.pop(idx) 
		os.remove(DATA_DIR+id+".json")
	except KeyError:
		bottle.response.status = 404
		return
	return

@bottle.route('/view') #local host route default. next function will be run for this url request
def account_view():
    payment_method = bottle.request.query.cat if bottle.request.query.cat else legacy_config['payment_methods'][0]["value"]

    # for backwards compatibility -- future all configuration in separate json and with uuid
    label = next(o for o in legacy_config["payment_methods"] if o['value'] == payment_method)['label']
    selected_view = [x for x in entries if 'payment_method' in x and x['payment_method'] == payment_method]
    selected_view.sort(key = lambda x: x["date"], reverse = False)
    for config in configurations:
        # print(config)
        if config[0]["type"] == "payment_method" and config[0]["value"] == payment_method:
            view_id = config[0]["id"]
            debt_payment = config[0]["debt_payment"]
            break
    else:
        view_id = ""
        debt_payment = 0
    # method_config = {}
	# for config in configuration:
	# 	if config.value = ""

    running = 0
    for obj in selected_view:
        running = running + obj['balance']
        obj['cumulative'] = running
        obj['show'] = {
            "cum": "{:.2f}".format(obj['cumulative']),
			"bal": "{:.2f}".format(obj['balance']),
			"amt": "{:.2f}".format(obj['amount']),
        }

    # print(json.dumps(selected_view,indent = 3))
    return bottle.template(
		'account',
		items = selected_view, 
		config = legacy_config, 
		selected = label, 
		value_selected = payment_method,
		view_id = view_id,
		initial_debt_payment = debt_payment
	)

@bottle.post('/update_debt_payment')
def update_debt_payment():
	data = bottle.request.json
	# print(data)
	if data['id'] != "":
		for config in configurations:
			if config[0]["id"] == data['id']:
				config[0]['debt_payment'] = data["debt_payment"]
				break
		with open(CONFIG_DIR + data['id'] + '.json', 'w') as file:
			json.dump(data, file, ensure_ascii=False, indent = 4)
	else:
		data["id"] = str(uuid4())
		filename = data["id"] + ".json"
		configurations.append( (data, filename) )
		# this writes a file even if error - should not do this in future
		with open(CONFIG_DIR + filename, 'w') as file:
			json.dump(data, file, ensure_ascii=False, indent = 4)
	
	return 'success'

@bottle.post('/update_payment_plan')
def update_payment_plan():
	data = bottle.request.json
	ids_to_update = [x['id'] for x in data]
	for entry in entries:
		try:
			idx = ids_to_update.index(entry['id'])
			entry['payoff_value'] = data[idx]['payoff_value']
			entry['payoff_type'] = data[idx]['payoff_type']

			with open(DATA_DIR + entry['id'] + '.json', 'w') as f:
				json.dump(entry, f, ensure_ascii=False, indent = 4)
				
			ids_to_update.pop(idx)
			data.pop(idx)
			if len(ids_to_update) < 1:
				break
		except ValueError: #expected error when entry not part of the payment method
			pass
		except Exception:
			traceback.print_exc()
			
	# print(json.dumps(entries,indent = 3))
	return 'success'







# LEGACY -------------------------------







@bottle.post('/income_new_entry')
def income_new_entry():
	#connect to Mongodo, budget_dev, temp collection
	connection = pymongo.MongoClient('localhost',27017)
	db = connection.budget_test
	incomes = db.income

	#get data from form
	new_date = datetime.datetime.strptime(bottle.request.forms.get('date'),"%Y-%m-%d")
	new_cat = bottle.request.forms.get('category')
	new_name = bottle.request.forms.get('name')

	new_amount = bottle.request.forms.get('amount')
	#if new_cat == 'interest':
	if any(x == new_cat for x in ['interest','dividend']):

		new_account = bottle.request.forms.get('account')
		new_json = {'date':new_date,'amount':float(new_amount), 'type':'income', 'category' \
		: new_cat,'name' : new_name, 'account' : new_account}

		if new_cat == 'interest':
			new_balance = float(bottle.request.forms.get('balance'))
			new_json['balance'] = new_balance

	else:
		new_gross_pay = float(bottle.request.forms.get('gross_pay'))
		new_income_tax= float(bottle.request.forms.get('income_tax'))
		new_ss= float(bottle.request.forms.get('ss_tax'))
		new_medicare= float(bottle.request.forms.get('medicare_tax'))
		new_dental= float(bottle.request.forms.get('dental'))
		new_vision= float(bottle.request.forms.get('vision'))
		new_health= float(bottle.request.forms.get('health'))
		new_retirement = float(bottle.request.forms.get('retirement'))
		new_retire_match=float(bottle.request.forms.get('retire_match'))
		new_add = float(bottle.request.forms.get('add'))
		new_life= float(bottle.request.forms.get('life'))

		new_json = {'date':new_date,'amount':float(new_amount), 'type':'income', 'category' \
		: new_cat,'name' : new_name, 'gross_pay': new_gross_pay, \
		'deductions': {'statutory': { 'income_tax': new_income_tax, 'social_security_tax': new_ss, 'medicare_tax': new_medicare}, \
		'voluntary':{'dental':new_dental, 'vision':new_vision, 'health': new_health},
		'retirement':{'retirement':new_retirement, 'match': new_retire_match}, 'other':{'add': new_add,'life':new_life}}}

	result = incomes.insert_one(new_json)

	return 'entry recorded <br/><a href="/income">Return to Income</a>'

@bottle.route('/test_entry/<id>')
def test_entry(id):
	#connect to Mongodo, budget_dev, temp collection
	connection = pymongo.MongoClient('localhost',27017)
	db = connection.budget_test
	incomes = db.income
	res = incomes.find_one({'_id': ObjectId(id)})

	if res['category'] == 'interest' :
		return_template = bottle.template('interest_entry',entry_data = res)
	else: #salary
		return_template = bottle.template('salary_entry',entry_data = res)


	return return_template


#One-time Expenses ----------------------------------------------------------------------


@bottle.route('/one_time_expense')
def one_time_expense():
	#connect to Mongodo, budget_dev, temp collection
	connection = pymongo.MongoClient('localhost',27017)
	db = connection.budget_test
	expenses = db.expense
	items = expenses.find().sort('date',pymongo.DESCENDING)
	entries = []
	for item in items:
		date_entry = item['date']
		try:
			date_entry = date_entry.date()
		except:
			print('issue with date')
			print(item)
		item['date'] = date_entry
		entries.append(item)
	return bottle.template('expenses',items = entries, config = config)


@bottle.post('/expense_new_entry')
def expense_new_entry():
	#connect to Mongodo, budget_dev, temp collection
	# connection = pymongo.MongoClient('localhost',27017)
	# db = connection.budget_test
	# expenses = db.expense
	expenses = global_expenses

	#get data from form
	new_date = datetime.datetime.strptime(bottle.request.forms.get('date'),"%Y-%m-%d")
	new_cat = bottle.request.forms.get('category')
	new_pay_meth = bottle.request.forms.get('payment_method')
	new_item = bottle.request.forms.get('item')
	new_amount = bottle.request.forms.get('amount')
	new_notes = bottle.request.forms.get('notes')

	new_json = {'date':new_date,'item':new_item, 'amount':float(new_amount), 'payment_method':new_pay_meth, 'category':new_cat, 'notes':new_notes}

	if any(x == new_cat for x in ['car','medical']):
		if new_cat == 'car':
			new_car = bottle.request.forms.get('car')
			new_type= bottle.request.forms.get('expense_type')

			new_json['car'] = new_car
			new_json['expense_type'] = new_type
		else:
			new_person = bottle.request.forms.get('person')
			new_type= bottle.request.forms.get('expense_type')

			new_json['person'] = new_person
			new_json['expense_type'] = new_type

	if new_cat == 'tech':
		new_subcat = bottle.request.forms.get('subcategory')
		new_json['subcategory'] = new_subcat
	if new_cat == 'house_upkeep':
		new_subcat = bottle.request.forms.get('subcategory')
		new_json['subcategory'] = new_subcat



	result = expenses.insert_one(new_json)

	return 'entry recorded <br/><a href="/one_time_expense">Return to One-Time Expenses</a>'

@bottle.route('/expense_entry/<id>')
def get_expense_entry(id):
	res = global_expenses.find_one({'_id': ObjectId(id)})
	return_template = bottle.template('json.tpl', json_string = dumps(res, indent = 4))
	return return_template

@bottle.post('/fix_expense_entry/<id>')
def fix_expense_entry(id):
	new_json_txt = bottle.request.forms.get('updated_entry')
	print(new_json_txt)
	new_json_dict = json.loads(new_json_txt)
	print(new_json_dict)

	if "$date" not in new_json_dict['date']:
		# print "fixing date"
		as_dt = datetime.datetime.strptime(new_json_dict['date'],"%Y-%m-%d")
		# print as_dt
		in_ms = time.mktime(as_dt.timetuple()) * 1000
		# print in_ms
		new_json_dict['date'] = {"$date": in_ms}
		
		# print new_json_txt
	
	# new_bson = loads(new_json_dict) # this doesnt work
	# print new_bson

	if new_json_dict['_id']["$oid"] == id:
		print("updating " + id)
		del new_json_dict['_id'] # need to remove id before update
		new_bson = loads(json.dumps(new_json_dict))
		print(new_bson)
		mongo_res = global_expenses.update_one({'_id': ObjectId(id)}, {"$set": new_bson}, upsert = False)
		print(mongo_res)
		bottle.response.status = 200
		return "success"
		
	else:
		print("ids dont match")
		print(new_json_dict['_id']['$oid'])
		print(id)
		bottle.response.status = 400
		return "Ids don't match"

#Monthly Expenses ----------------------------------------------------------------------


@bottle.route('/monthly_expense')
def monthly_expense():
	#connect to Mongodo, budget_dev, temp collection
	connection = pymongo.MongoClient('localhost',27017)
	db = connection.budget_test
	expenses = db.monthly_expense
	items = expenses.find().sort('date',pymongo.DESCENDING)

	return bottle.template('monthly_expenses',items = items)


@bottle.post('/monthly_expense_new_entry')
def monthly_expense_new_entry():
	#connect to Mongodo, budget_dev, temp collection
	connection = pymongo.MongoClient('localhost',27017)
	db = connection.budget_test
	expenses = db.monthly_expense

	#get data from form
	new_date = datetime.datetime.strptime(bottle.request.forms.get('date'),"%Y-%m-%d")
	new_cat = bottle.request.forms.get('category')
	new_item = bottle.request.forms.get('item')
	new_amount = bottle.request.forms.get('amount')

	new_json = {'date':new_date,'item':new_item, 'amount':float(new_amount), 'category':new_cat}
	result = expenses.insert_one(new_json)

	return 'entry recorded <br/><a href="/monthly_expense">Return to Monthly Expenses</a>'

#Debt -------------------------------------------------
@bottle.route('/debt') #local host route default. next function will be run for this url request
def debt():
	#connect to Mongodo, budget_dev, temp collection
	connection = pymongo.MongoClient('localhost',27017)
	db = connection.budget_test
	debt = db.debt
	items = debt.find().sort('date',pymongo.DESCENDING)

	#plot debt of last six months
	now = datetime.date.today()
	past_six = now - datetime.timedelta(6*365/12)
	past_six = past_six.replace(day = 1)
	past_six = datetime.datetime.combine(past_six, datetime.datetime.min.time())
	last_six = debt.find({'date':{'$gte': past_six}})
	series = set()

	'''
	for i, item in enumerate(last_six):
		#print i
		series.add(item['item'])
		#print series
		month_idx = (item['date'] - past_six).days/30
		#print item['date']
		#print month_idx
		if i > 0:
			#print len(ys)
			#print len(series)
			if len(ys) < len(series):
				ys.append([item['amount']])
				xs.append([month_idx])
			else:
				idx = series.index(item['item'])
				ys[idx].append(item['amount'])
				xs[idx].append(month_id)
		else:
			ys = [[item['amount']]]
			xs = [[month_idx]]
		#print xs
		#print ys
	'''
	return bottle.template('debt',items = items)

@bottle.post('/debt_new_entry')
def monthly_expense_new_entry():
	#connect to Mongodo, budget_dev, temp collection
	connection = pymongo.MongoClient('localhost',27017)
	db = connection.budget_test
	debt = db.debt

	#get data from form
	new_date = datetime.datetime.strptime(bottle.request.forms.get('date'),"%Y-%m-%d")
	new_cat = bottle.request.forms.get('category')
	new_item = bottle.request.forms.get('item')
	new_amount = bottle.request.forms.get('amount')

	new_json = {'date':new_date,'item':new_item, 'amount':float(new_amount), 'category':new_cat}
	result = debt.insert_one(new_json)

	return 'entry recorded <br/><a href="/debt">Return to Debt</a>'


bottle.run(host = 'localhost', port = PORT)

# CLEAN UP -------------------------------------------------------------------

# global_conn.close()
