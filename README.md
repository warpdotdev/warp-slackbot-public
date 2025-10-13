# Warp Slack Bot

A Slack bot that processes app mentions by running Warp CLI agent commands. The bot can handle both direct mentions and threaded conversations, providing full context to the Warp agent.

## Features

- 📱 Responds to Slack app mentions
- 🧵 Processes entire thread context for threaded conversations
- 🚀 Runs in Docker for consistent environment
- 📁 Persists repository data between container restarts
- 🔧 Integrates with Warp CLI agent

## Setup

### 1. Create Slack App from Manifest

The easiest way to set up your Slack app is using the provided manifest file:

1. **Go to https://api.slack.com/apps**
2. **Click "Create New App"**
3. **Select "From an app manifest"**
4. **Choose your workspace**
5. **Copy and paste the contents of `slack_app_manifest.json`**:
6. **Install the app to your workspace**


### 2. Environment Variables

Copy the example environment file and fill in your tokens:

```bash
cp .env.example .env
```

Edit `.env` with your credentials:

Follow the instructions in `.env` for where to get relevant variables.

### 3. Repository Configuration

Create your repository configuration from the template:

```bash
cp repos.yaml.template repos.yaml
```

Then edit `repos.yaml` to specify which repositories to monitor:

```yaml
repositories:
  - url: "username/repository-name"
    branch: "main"
  - url: "org/private-repo"
    branch: "develop"
```

**Repository Configuration Options:**
- `url`: GitHub repository in format `owner/repo-name`
- `branch`: Git branch to checkout and keep up to date as the 'base' branch for that repo

**Examples:**
```yaml
repositories:
  - url: "mycompany/secret-api"
    branch: "production"

  - url: "mycompany/frontend"
    branch: "main"
```

### 4. Setting Up Your Slackbot Prompt

The Slackbot uses a customizable prompt to process Slack messages and generate appropriate responses. Here's how to set it up:

1. **See an example prompt** - We use a comprehensive prompt at Warp to power our Slackbot that handles code questions and formulates PRs based on Slack discussions.

2. **Use Warp Drive Notebooks** - The Slackbot is designed to work with prompts stored in [Warp Drive Notebooks](https://docs.warp.dev/knowledge-and-collaboration/warp-drive/notebooks). This allows you to dynamically iterate on your prompt without needing to re-deploy the bot.

3. **Configure the notebook ID** - To get your notebook ID:
   - Type `@` in your Warp input
   - Select your notebook from the dropdown
   - Copy the alphanumeric code that appears after `<notebook:{id}>`
   - Add this ID to your `.env` file as the notebook reference

This setup enables you to refine your bot's behavior by editing the notebook prompt in real-time through the Warp Drive interface.


## Running the Bot

### Development

```bash
# Build and start the container
docker-compose up --build

# Run in background
docker-compose up -d

# View logs
docker-compose logs -f

# Stop the bot
docker-compose down
```

## Usage

1. **Invite the bot** to channels where you want to use it
2. **Mention the bot** with `@Warp your message here`
3. **Use in threads** - the bot will include full thread context

Example interactions:
```
@Warp analyze the recent changes in the main branch
@Warp help me fix the bug discussed in the thread.
```
