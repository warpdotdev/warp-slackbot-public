def get_prompt(notebook_id, full_context_with_metadata):
    prompt_text = f"""
      Please process <notebook:{notebook_id}> and follow all instructions.
      Please use this slack thread: {full_context_with_metadata}
    
      <tool> Send Slack Message
            To send messages to Slack please use the following tool schema directly:
            # Send message to a channel
            /app/slack_send.sh '#general' 'Hello world'

            # Send message using channel ID
            /app/slack_send.sh 'C1234567890' 'Hello from script'

            # Reply in a thread
            /app/slack_send.sh 'C1234567890' 'Reply message' '1234567890.123456'

            Always use a ts to thread the reply
      </tool>
    """
    return repr(prompt_text)



