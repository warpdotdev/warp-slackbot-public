from slack_bolt import App
from slack_bolt.adapter.socket_mode import SocketModeHandler
import os
import subprocess
from prompt import get_prompt
from datetime import datetime

SLACK_BOT_TOKEN = os.environ.get("SLACK_BOT_TOKEN")
SLACK_APP_TOKEN = os.environ.get("SLACK_APP_TOKEN")
NOTEBOOK_ID = os.environ.get("NOTEBOOK_ID")
WARP_API_KEY = os.environ.get("WARP_API_KEY")

# Initialize the Bolt app
app = App(token=SLACK_BOT_TOKEN)

# Listen for app mentions
@app.event("app_mention")
def handle_app_mentions(body, say, logger, client):
    event = body.get("event", {})
    channel = event.get("channel")
    text = event.get("text")
    user = event.get("user")
    thread_ts = event.get("thread_ts")
    ts = event.get("ts") 
    logger.info(f"Got mention from user {user} in channel {channel}: {text}")
    
    full_context = text
    if thread_ts:
        try:
            # Fetch the entire thread
            result = client.conversations_replies(
                channel=channel,
                ts=thread_ts
            )
            
            if result["ok"]:
                messages = result["messages"]
                # Build context from all messages in the thread
                thread_context = []
                for msg in messages:
                    msg_user = msg.get("user", "unknown")
                    msg_text = msg.get("text", "")
                    thread_context.append(f"User {msg_user}: {msg_text}")
                
                full_context = "\n".join(thread_context)
            
        except Exception as e:
            print(f"Error fetching thread context: {e}", flush=True)
            logger.error(f"Error fetching thread context: {e}")
    
    # Add Slack metadata to the full context
    slack_metadata = f"\n\nSlack details: channel {channel}, thread_ts {thread_ts if thread_ts else 'N/A'}, message_id {ts}, user {user}"
    full_context_with_metadata = full_context + slack_metadata
    
    # Run the warp agent command with the full context (thread or single message)
    print("full",full_context_with_metadata, flush=True)
    try:
        say("Processing request...", thread_ts=thread_ts or ts)
        #TODO move slack_send 'tool' into main prompt
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        logfile = f"/app/logs/{timestamp}.log"
        cmd = (
            f"mkdir -p /app/logs && "
            f"warp-cli agent run "
            f"--api-key {WARP_API_KEY} "
            f"--prompt {get_prompt(NOTEBOOK_ID, full_context_with_metadata)} "
            f"| tee {logfile}"
        )
        result = subprocess.run(cmd, shell=True, text=True)
        
        if result.returncode == 0:
            response = f"Command executed successfully. Output logged to {logfile}"
        else:
            response = f"Command failed with return code {result.returncode}. Check {logfile} for details."
        say(response, thread_ts=thread_ts or ts)
            
    except Exception as e:
        response = f"Error running command: {str(e)}"
        say(response, thread_ts=thread_ts or ts)
        


# Run the app with Socket Mode
if __name__ == "__main__":
    handler = SocketModeHandler(app, SLACK_APP_TOKEN)
    handler.start()
