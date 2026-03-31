# Local Development Guide: Enabling MongoDB Replica Sets

To use MongoDB Transactions locally for development, you must convert your standalone MongoDB instance into a single-node Replica Set.

## Prerequisites
- MongoDB installed locally (Community Edition 4.0+)
- Accessible via Command Prompt / PowerShell

## Steps

### 1. Stop your existing MongoDB service
If you are running MongoDB as a Windows Service, stop it via the Services Manager or run:
```powershell
net stop MongoDB
```

### 2. Update Configuration (`mongod.cfg`)
Locate your `mongod.cfg` (usually in `C:\Program Files\MongoDB\Server\<version>\bin`). Add the following lines:
```yaml
replication:
  replSetName: "rs0"
```

### 3. Restart MongoDB
Start the service again:
```powershell
net start MongoDB
```

### 4. Initialize the Replica Set
Open the `mongosh` or `mongo` shell and run:
```javascript
rs.initiate()
```

Wait a few seconds. You should see the prompt change to `rs0:PRIMARY>`. 

### 5. Update your `.env`
In your `finance-app/backend/.env`, set:
```env
ENABLE_TRANSACTIONS=true
```

## Troubleshooting
If you encounter `Command failed with error: ReplicaSetNoPrimary` after initialization, ensure that your `MONGO_URI` is correct. For Atlas connection strings, transactions are enabled by default.
