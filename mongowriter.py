import pymongo

client = pymongo.MongoClient("mongodb://3.8.6.157:27017/")
db = client.get_database("WHSmith")
collection = db.get_collection("Books")

#json data as list of books
books = [
    {"Name":"Tale of two cities","Price":"50","Category":"Fiction"},
    {"Name":"Tom Sawyer","Price":"20","Category":"Children", "Author":"Charles Dickens"},
    {"Name":"Truth and little malice","Price":"150","Category":"Autobiography", "Author": "Kushwanth Singh"}
]

#iterate and insert 
for book in books:
    collection.insert_one(book)

#close conn

