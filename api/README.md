# ResiWash API server (Express, TypeORM)

This is the directory containing files to run the server.

### Prerequisites
1. Postgres must be installed.
- Setup a user and a database.

### Getting started for first timers
1. Open a terminal in this directory
2. Run `npm install`
3. Create and populate the `.env` file:
```
DB_NAME=[insert]
DB_USER=[insert]
DB_PASSWORD=[insert]
DB_HOST=[insert]

SESSION_KEY = "resiwash-is-awesome"
```
4. Create an <b>issue</b> with your email address, stating you want to work on the project. An email with a `service-account.json` file will be emailed to you, and you should put this file in this directory.
5. Run `npm run dev`.