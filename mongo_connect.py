import pymongo
from bson.objectid import ObjectId

def mongo_connect(collection):
	connection = pymongo.MongoClient('localhost',27017)
	db = connection.budget_test
	records = db['collection']
	return records
	