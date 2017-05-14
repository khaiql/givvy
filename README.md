# Givvy

### Deploy to Heroku

One click deploy

[![Deploy now](https://www.herokucdn.com/deploy/button.svg)](https://www.heroku.com/deploy/?template=https://github.com/TODO)

### Setting up your Slack App

You must setup your own Slack App manually.

To do this, click this [link](https://api.slack.com/apps?new_app=1) to begin.

You should setup the following:

- Slash Commands:
	- `/give` points to `<your_heroku_url>/api/v1/slack`
	- `/redeem` points to `<your_heroku_url>/api/v1/slack_redeem`
- OAuth Permissions:
	- `users:read`
	- `users:read.email` for future features
	- `chat:write:bot`

### Improve performance with caching avatars

TODO

### ENV vars

This project uses `dotenv` gem to load `.env` (sample in **.env.sample** file)

`SLACK_TOKEN=`
Copy and paste OAuth token from Slack here, after creating your Slack app

`ADMIN_PASSWORD=givvy`
Password to access admin panel

`TZ="Asia/Ho_Chi_Minh"`
Default timezone

`DEFAULT_ALLOWANCE=150`
Default allowance per user per month

`ANNOUNCE_MODE="in_channel"`
Send announcement in-channel, where the user posted the command. Other value is `"public"`.

`DEFAULT_CHANNEL="#general"`
If announcement mode is public, then the response message will be posted into this default channel.

### Tech stack

- Rudy 2.3
- Rails 5
- Postgres DB
- Custom `.buildpacks` to enable `wkhtmltoX`
